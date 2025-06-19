# Daily Campaign Management Workflow - ViSto Capital

## 🎯 Overview
This guide outlines the daily process for creating language-specific campaigns and routing leads to appropriate agents.

## 📅 Daily Workflow

### Step 1: Morning Campaign Preparation (8:00 AM)

#### **1.1 Review Lead Data in Supabase**
```sql
-- Check today's leads by language
SELECT 
    preferred_language,
    COUNT(*) as lead_count,
    AVG(credit_score) as avg_credit_score,
    SUM(total_loan_amount) as total_potential_loans
FROM leads 
WHERE status IN ('new', 'follow_up', 'interested')
    AND last_contact_date < CURRENT_DATE
    OR last_contact_date IS NULL
GROUP BY preferred_language;
```

#### **1.2 Update Lead Routing Information**
```sql
-- Update leads for Spanish campaign
UPDATE leads 
SET 
    campaign_id = 'visto-spanish-2024-01-15',
    segment_name = 'Spanish Daily Follow-up',
    routing_profile = 'Spanish-Speaking-Profile',
    agent_language_requirement = 'spanish'
WHERE preferred_language IN ('spanish', 'español')
    AND status IN ('new', 'follow_up', 'interested');

-- Update leads for English campaign  
UPDATE leads
SET 
    campaign_id = 'visto-english-2024-01-15',
    segment_name = 'English Daily Follow-up', 
    routing_profile = 'English-Speaking-Profile',
    agent_language_requirement = 'english'
WHERE preferred_language = 'english'
    AND status IN ('new', 'follow_up', 'interested');
```

### Step 2: Create Pinpoint Segments (8:30 AM)

#### **2.1 Spanish Speaking Segment**
```json
{
  "Name": "Spanish-Leads-2024-01-15",
  "SegmentType": "DIMENSIONAL",
  "Dimensions": {
    "UserAttributes": {
      "Language": {
        "Values": ["Spanish", "Español", "spanish", "español"],
        "AttributeType": "INCLUSIVE"
      },
      "LeadStatus": {
        "Values": ["new", "follow_up", "interested"],
        "AttributeType": "INCLUSIVE"  
      },
      "LastContactDate": {
        "Values": ["2024-01-14"],
        "AttributeType": "BEFORE"
      }
    }
  }
}
```

#### **2.2 English Speaking Segment**
```json
{
  "Name": "English-Leads-2024-01-15", 
  "SegmentType": "DIMENSIONAL",
  "Dimensions": {
    "UserAttributes": {
      "Language": {
        "Values": ["English", "english"],
        "AttributeType": "INCLUSIVE"
      },
      "LeadStatus": {
        "Values": ["new", "follow_up", "interested"],
        "AttributeType": "INCLUSIVE"
      },
      "LastContactDate": {
        "Values": ["2024-01-14"],
        "AttributeType": "BEFORE"
      }
    }
  }
}
```

### Step 3: Create Voice Templates (9:00 AM)

#### **3.1 Spanish Voice Template**
```
Hola {{User.UserAttributes.FirstName}}, 

Soy {{Agent.FirstName}} de ViSto Capital. Le llamo porque usted expresó interés en nuestros servicios de préstamos para propiedades.

Veo en nuestro sistema que tiene {{User.UserAttributes.PropertyCount}} propiedades y está buscando un préstamo de ${{User.UserAttributes.LoanAmount}}.

¿Tiene unos minutos para hablar sobre cómo podemos ayudarle con su financiamiento?

Muchas gracias.
```

#### **3.2 English Voice Template**
```
Hello {{User.UserAttributes.FirstName}},

This is {{Agent.FirstName}} from ViSto Capital. I'm calling because you expressed interest in our property lending services.

I see in our system that you have {{User.UserAttributes.PropertyCount}} properties and are looking for a loan of ${{User.UserAttributes.LoanAmount}}.

Do you have a few minutes to discuss how we can help with your financing needs?

Thank you.
```

### Step 4: Create and Launch Campaigns (9:30 AM)

#### **4.1 Spanish Campaign Configuration**
```json
{
  "Name": "ViSto-Spanish-Daily-2024-01-15",
  "Description": "Daily Spanish speaking leads follow-up",
  "Schedule": {
    "StartTime": "2024-01-15T14:00:00Z",
    "EndTime": "2024-01-15T22:00:00Z",
    "Timezone": "America/New_York"
  },
  "SegmentId": "spanish-leads-segment-id",
  "MessageConfiguration": {
    "VoiceMessage": {
      "VoiceId": "Conchita",
      "LanguageCode": "es-ES",
      "Body": "spanish-voice-template"
    }
  },
  "AdditionalTreatments": [
    {
      "Id": "spanish-treatment",
      "MessageConfiguration": {
        "TreatmentDescription": "Spanish speaking agent routing"
      },
      "SizePercent": 100
    }
  ]
}
```

#### **4.2 English Campaign Configuration**  
```json
{
  "Name": "ViSto-English-Daily-2024-01-15",
  "Description": "Daily English speaking leads follow-up",
  "Schedule": {
    "StartTime": "2024-01-15T14:00:00Z", 
    "EndTime": "2024-01-15T22:00:00Z",
    "Timezone": "America/New_York"
  },
  "SegmentId": "english-leads-segment-id",
  "MessageConfiguration": {
    "VoiceMessage": {
      "VoiceId": "Joanna",
      "LanguageCode": "en-US", 
      "Body": "english-voice-template"
    }
  }
}
```

### Step 5: Monitor Campaign Performance (Throughout Day)

#### **5.1 Real-time Monitoring Dashboard**
```sql
-- Campaign performance by language
SELECT 
    l.preferred_language,
    l.campaign_id,
    COUNT(*) as total_calls,
    COUNT(CASE WHEN l.status = 'contacted' THEN 1 END) as successful_contacts,
    COUNT(CASE WHEN l.status = 'interested' THEN 1 END) as interested_leads,
    AVG(l.total_loan_amount) as avg_loan_amount
FROM leads l
WHERE l.campaign_id LIKE '%2024-01-15%'
GROUP BY l.preferred_language, l.campaign_id;
```

#### **5.2 Agent Performance by Language**
```sql
-- Agent utilization by language queue
SELECT 
    agent_language_requirement,
    assigned_agent,
    COUNT(*) as calls_handled,
    AVG(EXTRACT(EPOCH FROM (updated_at - created_at))/60) as avg_call_duration_minutes
FROM leads 
WHERE campaign_id LIKE '%2024-01-15%'
    AND status = 'contacted'
GROUP BY agent_language_requirement, assigned_agent;
```

## 🎛️ Amazon Connect Agent Configuration

### Spanish-Speaking Agents Setup
```
Agent Profile: Maria Gonzalez
- Routing Profile: Spanish-Speaking-Profile
- Queues: ViSto-Spanish-Agents (Priority 1)
- Skills: Spanish (Level 10), Lending (Level 8), Customer Service (Level 9)
- Phone Type: Soft phone
- Auto-Accept: Enabled for voice

Agent Profile: Carlos Rodriguez  
- Routing Profile: Spanish-Speaking-Profile
- Queues: ViSto-Spanish-Agents (Priority 1)
- Skills: Spanish (Level 10), Lending (Level 9), Customer Service (Level 8)
```

### English-Speaking Agents Setup
```
Agent Profile: John Smith
- Routing Profile: English-Speaking-Profile  
- Queues: ViSto-English-Agents (Priority 1)
- Skills: English (Level 10), Lending (Level 9), Customer Service (Level 8)

Agent Profile: Sarah Johnson
- Routing Profile: English-Speaking-Profile
- Queues: ViSto-English-Agents (Priority 1) 
- Skills: English (Level 10), Lending (Level 8), Customer Service (Level 9)
```

## 📊 End-of-Day Reporting (6:00 PM)

### Campaign Results Summary
```sql
-- Daily campaign summary
SELECT 
    DATE(created_at) as campaign_date,
    preferred_language,
    campaign_id,
    COUNT(*) as total_leads,
    COUNT(CASE WHEN status = 'contacted' THEN 1 END) as contacted,
    COUNT(CASE WHEN status = 'interested' THEN 1 END) as interested,
    COUNT(CASE WHEN status = 'not_interested' THEN 1 END) as not_interested,
    COUNT(CASE WHEN status = 'callback' THEN 1 END) as callbacks_scheduled,
    SUM(total_loan_amount) as total_potential_revenue
FROM leads 
WHERE DATE(created_at) = CURRENT_DATE
GROUP BY DATE(created_at), preferred_language, campaign_id;
```

## 🔄 Next Day Preparation

### Update Lead Statuses
```sql
-- Prepare leads for next day follow-up
UPDATE leads 
SET 
    last_contact_date = CURRENT_DATE,
    status = CASE 
        WHEN status = 'not_interested' THEN 'do_not_call'
        WHEN status = 'callback' THEN 'follow_up'
        WHEN status = 'interested' THEN 'hot_lead'
        ELSE status
    END
WHERE campaign_id LIKE '%' || TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD') || '%';
```

## 🎯 Key Success Metrics

1. **Contact Rate**: % of leads successfully contacted
2. **Language Routing Accuracy**: % of calls routed to correct language agents  
3. **Agent Utilization**: % of time agents spend on calls vs. waiting
4. **Lead Conversion**: % of contacted leads showing interest
5. **Revenue Pipeline**: Total potential loan amounts in pipeline

## 🚨 Troubleshooting

### Common Issues:
1. **No Spanish agents available**: Calls overflow to bilingual English agents
2. **High abandonment rate**: Reduce concurrent calls or add more agents
3. **Wrong language routing**: Check Supabase `preferred_language` data quality
4. **Campaign not launching**: Verify Pinpoint segment has active endpoints

This workflow ensures efficient, language-appropriate lead management while maximizing agent productivity and customer satisfaction. 