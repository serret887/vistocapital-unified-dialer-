const { createClient } = require('@supabase/supabase-js');
const AWS = require('aws-sdk');

const secretsManager = new AWS.SecretsManager();
const dynamodb = new AWS.DynamoDB.DocumentClient();

// Cache for Supabase client and credentials
let supabaseClient = null;
let supabaseCredentials = null;

/**
 * Gets Supabase credentials from AWS Secrets Manager
 */
async function getSupabaseCredentials() {
    if (supabaseCredentials) {
        return supabaseCredentials;
    }
    
    try {
        const secretArn = process.env.SUPABASE_SECRET_ARN;
        const secret = await secretsManager.getSecretValue({ SecretId: secretArn }).promise();
        supabaseCredentials = JSON.parse(secret.SecretString);
        return supabaseCredentials;
    } catch (error) {
        console.error('Error retrieving Supabase credentials:', error);
        throw error;
    }
}

/**
 * Initializes Supabase client if not already initialized
 */
async function getSupabaseClient() {
    if (supabaseClient) {
        return supabaseClient;
    }
    
    const credentials = await getSupabaseCredentials();
    supabaseClient = createClient(credentials.url, credentials.anon_key);
    return supabaseClient;
}

/**
 * Caches lead data in DynamoDB for faster subsequent lookups
 */
async function cacheLeadData(customerNumber, leadData) {
    const cacheTableName = process.env.LEAD_CACHE_TABLE;
    const ttl = Math.floor(Date.now() / 1000) + (24 * 60 * 60); // Cache for 24 hours
    
    try {
        await dynamodb.put({
            TableName: cacheTableName,
            Item: {
                customerNumber: customerNumber,
                leadData: leadData,
                ttl: ttl,
                lastUpdated: new Date().toISOString()
            }
        }).promise();
        
        console.log(`Cached lead data for customer: ${customerNumber}`);
    } catch (error) {
        console.error('Error caching lead data:', error);
        // Don't throw error, just log it - caching failure shouldn't break the flow
    }
}

/**
 * Retrieves cached lead data from DynamoDB
 */
async function getCachedLeadData(customerNumber) {
    const cacheTableName = process.env.LEAD_CACHE_TABLE;
    
    try {
        const result = await dynamodb.get({
            TableName: cacheTableName,
            Key: { customerNumber: customerNumber }
        }).promise();
        
        if (result.Item) {
            console.log(`Retrieved cached lead data for customer: ${customerNumber}`);
            return result.Item.leadData;
        }
    } catch (error) {
        console.error('Error retrieving cached lead data:', error);
        // Return null if cache lookup fails
    }
    
    return null;
}

/**
 * Queries Supabase for lead information
 */
async function querySupabaseForLead(customerNumber) {
    const supabase = await getSupabaseClient();
    
    try {
        // Query leads table - adjust table name and columns as needed
        const { data, error } = await supabase
            .from('leads')
            .select(`
                id,
                customer_number,
                first_name,
                last_name,
                email,
                phone,
                status,
                property_count,
                total_loan_amount,
                credit_score,
                last_contact_date,
                notes,
                priority_level,
                lead_source,
                assigned_agent,
                preferred_language,
                agent_language_requirement,
                campaign_id,
                segment_name,
                routing_profile,
                created_at,
                updated_at
            `)
            .eq('customer_number', customerNumber)
            .single();
        
        if (error) {
            if (error.code === 'PGRST116') {
                // No rows returned
                console.log(`No lead found for customer number: ${customerNumber}`);
                return null;
            }
            throw error;
        }
        
        console.log(`Successfully retrieved lead data for customer: ${customerNumber}`);
        return data;
    } catch (error) {
        console.error('Error querying Supabase:', error);
        throw error;
    }
}

/**
 * Formats lead data for Amazon Connect attributes
 */
function formatLeadDataForConnect(leadData) {
    if (!leadData) {
        return {
            leadFound: "false",
            leadName: "Unknown Customer",
            leadStatus: "Unknown",
            leadEmail: "",
            leadPhone: "",
            propertyCount: "0",
            totalLoanAmount: "0",
            creditScore: "0",
            lastContactDate: "",
            priorityLevel: "normal",
            leadSource: "unknown",
            assignedAgent: "",
            leadNotes: ""
        };
    }
    
    const fullName = `${leadData.first_name || ''} ${leadData.last_name || ''}`.trim();
    
    return {
        leadFound: "true",
        leadId: leadData.id?.toString() || "",
        leadName: fullName || "Unknown Customer",
        leadFirstName: leadData.first_name || "",
        leadLastName: leadData.last_name || "",
        leadEmail: leadData.email || "",
        leadPhone: leadData.phone || "",
        leadStatus: leadData.status || "unknown",
        propertyCount: leadData.property_count?.toString() || "0",
        totalLoanAmount: leadData.total_loan_amount?.toString() || "0",
        creditScore: leadData.credit_score?.toString() || "0",
        lastContactDate: leadData.last_contact_date || "",
        priorityLevel: leadData.priority_level || "normal",
        leadSource: leadData.lead_source || "unknown",
        assignedAgent: leadData.assigned_agent || "",
        leadNotes: leadData.notes || "",
        customerNumber: leadData.customer_number || "",
        preferredLanguage: leadData.preferred_language || "english",
        agentLanguageRequirement: leadData.agent_language_requirement || "english",
        campaignId: leadData.campaign_id || "",
        segmentName: leadData.segment_name || "",
        routingProfile: leadData.routing_profile || "Basic Routing Profile"
    };
}

/**
 * Main Lambda handler
 */
exports.handler = async (event) => {
    console.log('Received event:', JSON.stringify(event, null, 2));
    
    try {
        // Extract customer number from Connect event
        // This could come from different places depending on how Connect is configured
        let customerNumber = null;
        
        if (event.Details && event.Details.Parameters) {
            // Called from Connect contact flow
            customerNumber = event.Details.Parameters.customerNumber;
        } else if (event.customerNumber) {
            // Direct invocation
            customerNumber = event.customerNumber;
        } else if (event.Details && event.Details.ContactData && event.Details.ContactData.CustomerEndpoint) {
            // Extract from customer phone number
            customerNumber = event.Details.ContactData.CustomerEndpoint.Address;
        }
        
        if (!customerNumber) {
            console.error('No customer number provided in event');
            return formatLeadDataForConnect(null);
        }
        
        // Clean up customer number (remove country code, formatting, etc.)
        customerNumber = customerNumber.replace(/^\+?1?/, '').replace(/\D/g, '');
        
        console.log(`Looking up customer: ${customerNumber}`);
        
        // First, try to get cached data
        let leadData = await getCachedLeadData(customerNumber);
        
        if (!leadData) {
            // If not cached, query Supabase
            leadData = await querySupabaseForLead(customerNumber);
            
            // Cache the result (even if null) to avoid repeated API calls
            if (leadData) {
                await cacheLeadData(customerNumber, leadData);
            }
        }
        
        const formattedData = formatLeadDataForConnect(leadData);
        
        console.log('Returning formatted lead data:', JSON.stringify(formattedData, null, 2));
        
        return formattedData;
        
    } catch (error) {
        console.error('Error in Lambda handler:', error);
        
        // Return default data structure on error to avoid breaking Connect flow
        return {
            leadFound: "false",
            leadName: "Error - Data Unavailable",
            leadStatus: "error",
            errorMessage: error.message || "Unknown error occurred"
        };
    }
}; 