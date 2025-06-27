import * as cdk from 'aws-cdk-lib';
import * as connect from 'aws-cdk-lib/aws-connect';
import { AwsCustomResource, AwsCustomResourcePolicy, PhysicalResourceId } from 'aws-cdk-lib/custom-resources';
import { Construct } from 'constructs';
import * as fs from 'fs';
import * as path from 'path';
import * as iam from 'aws-cdk-lib/aws-iam';

interface ConnectAutomationStackProps extends cdk.StackProps {
  environment: string;
  stackName: string;
}

export class ConnectAutomationStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: ConnectAutomationStackProps) {
    super(scope, id, props);

    // Import values from existing SAM stack
    const connectInstanceId = new cdk.CfnParameter(this, 'ConnectInstanceId', {
      type: 'String',
      description: 'Amazon Connect Instance ID (from SAM stack)',
    });

    // Environment-specific configuration
    const envConfig = this.getEnvironmentConfig(props.environment);

    // 1. Create/Import Contact Flow
    // Commented out UnifiedDialerContactFlow custom resource as contact flow will be managed manually
    // const unifiedDialerContactFlow = this.createContactFlow(connectInstanceId.valueAsString, envConfig);

    // 2. Create Spanish and English Queues
    const queues = this.createLanguageQueues(connectInstanceId.valueAsString, envConfig);

    // 3. Create Routing Profiles
    const routingProfiles = this.createRoutingProfiles(
      connectInstanceId.valueAsString, 
      queues, 
      envConfig
    );

    // 4. Associate Lambda Functions (when available)
    // this.associateLambdaFunctions(connectInstanceId.valueAsString, envConfig);

    // Outputs
    // new cdk.CfnOutput(this, 'ContactFlowId', {
    //   value: unifiedDialerContactFlow.getResponseField('ContactFlowId'),
    //   description: 'Unified Dialer Contact Flow ID',
    //   exportName: `${props.stackName}-ContactFlowId`,
    // });

    new cdk.CfnOutput(this, 'SpanishQueueId', {
      value: queues.spanish.getResponseField('QueueId'),
      description: 'Spanish Queue ID',
      exportName: `${props.stackName}-SpanishQueueId`,
    });

    new cdk.CfnOutput(this, 'EnglishQueueId', {
      value: queues.english.getResponseField('QueueId'),
      description: 'English Queue ID',
      exportName: `${props.stackName}-EnglishQueueId`,
    });
  }

  private getEnvironmentConfig(environment: string) {
    const configs = {
      dev: {
        concurrentCalls: 3,
        maxContactsInQueue: 50,
        timeout: 30,
      },
      staging: {
        concurrentCalls: 3,
        maxContactsInQueue: 100,
        timeout: 60,
      },
      prod: {
        concurrentCalls: 10,
        maxContactsInQueue: 500,
        timeout: 120,
      }
    };
    return configs[environment as keyof typeof configs] || configs.dev;
  }

  private createContactFlow(instanceId: string, envConfig: any) {
    // Load contact flow from file
    const contactFlowPath = path.join(__dirname, '../../contact-flows/UnifiedDialerContactFlow.json');
    let contactFlowContent = '';
    
    try {
      contactFlowContent = fs.readFileSync(contactFlowPath, 'utf8');
    } catch (error) {
      // Fallback to a basic contact flow if file doesn't exist
      contactFlowContent = JSON.stringify({
        "Version": "2019-10-30",
        "StartAction": "12345678-1234-1234-1234-123456789012",
        "Actions": [
          {
            "Identifier": "12345678-1234-1234-1234-123456789012",
            "Type": "MessageParticipant",
            "Parameters": {
              "Text": "Welcome to ViSto Capital Unified Dialer"
            },
            "Transitions": {
              "NextAction": "abcdef12-abcd-abcd-abcd-abcdefghijkl"
            }
          },
          {
            "Identifier": "abcdef12-abcd-abcd-abcd-abcdefghijkl",
            "Type": "DisconnectParticipant",
            "Parameters": {}
          }
        ]
      });
    }

    // Commented out UnifiedDialerContactFlow custom resource as contact flow will be managed manually
    // const unifiedDialerContactFlow = new AwsCustomResource(this, 'UnifiedDialerContactFlow', {
    //   onCreate: {
    //     service: 'Connect',
    //     action: 'createContactFlow',
    //     parameters: {
    //       InstanceId: instanceId,
    //       Name: 'UnifiedDialerContactFlow',
    //       Type: 'CONTACT_FLOW',
    //       Description: 'Automated contact flow for ViSto Capital unified dialer with Supabase integration',
    //       Content: contactFlowContent,
    //       Tags: {
    //         Environment: this.node.tryGetContext('environment') || 'dev',
    //       },
    //     },
    //     physicalResourceId: PhysicalResourceId.fromResponse('ContactFlowId'),
    //   },
    //   onDelete: {
    //     service: 'Connect',
    //     action: 'deleteContactFlow',
    //     parameters: {
    //       InstanceId: instanceId,
    //       ContactFlowId: '' // No deletion since managed manually
    //     },
    //   },
    //   policy: AwsCustomResourcePolicy.fromSdkCalls({
    //     resources: AwsCustomResourcePolicy.ANY_RESOURCE,
    //   }),
    // });

    return undefined; // Placeholder return, actual implementation needed
  }

  private createLanguageQueues(instanceId: string, envConfig: any) {
    // First, get the default Hours of Operation
    const hoursOfOperation = new AwsCustomResource(this, 'GetHoursOfOperation', {
      onCreate: {
        service: 'Connect',
        action: 'listHoursOfOperations',
        parameters: {
          InstanceId: instanceId,
        },
        physicalResourceId: PhysicalResourceId.of('GetHoursOfOperation'),
      },
      policy: AwsCustomResourcePolicy.fromSdkCalls({
        resources: AwsCustomResourcePolicy.ANY_RESOURCE,
      }),
    });

    // Update the policy for EnglishQueue and SpanishQueue custom resources
    const queuePolicy = new iam.PolicyStatement({
      actions: [
        "connect:TagResource",
        "connect:UntagResource",
        "connect:CreateQueue",
        "connect:DeleteQueue",
        "connect:UpdateQueueName",
        "connect:UpdateQueueHoursOfOperation",
        "connect:UpdateQueueMaxContacts",
        "connect:UpdateQueueStatus"
      ],
      resources: [
        "arn:aws:connect:us-east-1:159781649891:instance/*/queue/*",
        "arn:aws:connect:us-east-1:159781649891:instance/*/operating-hours/*",
        "arn:aws:connect:us-east-1:159781649891:instance/*/routing-profile/*",
        "arn:aws:connect:us-east-1:159781649891:instance/*/contact-flow/*",
        "arn:aws:connect:us-east-1:159781649891:instance/*/lambda-function/*",
        "arn:aws:connect:us-east-1:159781649891:instance/*/user/*",
      ]
    });

    // Create Spanish Queue
    const spanishQueue = new AwsCustomResource(this, 'SpanishQueue', {
      onCreate: {
        service: 'Connect',
        action: 'createQueue',
        parameters: {
          InstanceId: instanceId,
          Name: 'Spanish-Customer-Queue',
          Description: 'Queue for Spanish-speaking customers - ViSto Capital',
          HoursOfOperationId: hoursOfOperation.getResponseField('HoursOfOperationSummaryList.0.Id'),
          MaxContacts: envConfig.maxContactsInQueue,
          Tags: {
            Language: 'Spanish',
            Environment: this.node.tryGetContext('environment') || 'dev',
            Project: 'ViStoCapital-UnifiedDialer'
          }
        },
        physicalResourceId: PhysicalResourceId.fromResponse('QueueId'),
      },
      policy: AwsCustomResourcePolicy.fromStatements([queuePolicy]),
    });

    // Create English Queue
    const englishQueue = new AwsCustomResource(this, 'EnglishQueue', {
      onCreate: {
        service: 'Connect',
        action: 'createQueue',
        parameters: {
          InstanceId: instanceId,
          Name: 'English-Customer-Queue',
          Description: 'Queue for English-speaking customers - ViSto Capital',
          HoursOfOperationId: hoursOfOperation.getResponseField('HoursOfOperationSummaryList.0.Id'),
          MaxContacts: envConfig.maxContactsInQueue,
          Tags: {
            Language: 'English',
            Environment: this.node.tryGetContext('environment') || 'dev',
            Project: 'ViStoCapital-UnifiedDialer'
          }
        },
        physicalResourceId: PhysicalResourceId.fromResponse('QueueId'),
      },
      policy: AwsCustomResourcePolicy.fromStatements([queuePolicy]),
    });

    // Ensure Spanish queue is created after Hours of Operation lookup
    spanishQueue.node.addDependency(hoursOfOperation);
    englishQueue.node.addDependency(hoursOfOperation);

    return {
      spanish: spanishQueue,
      english: englishQueue
    };
  }

  private createRoutingProfiles(instanceId: string, queues: any, envConfig: any) {
    // Create Spanish Routing Profile
    const spanishProfile = new AwsCustomResource(this, 'SpanishRoutingProfile', {
      onCreate: {
        service: 'Connect',
        action: 'createRoutingProfile',
        parameters: {
          InstanceId: instanceId,
          Name: 'Spanish-Agents-Profile',
          Description: 'Routing profile for Spanish-speaking agents',
          DefaultOutboundQueueId: queues.spanish.getResponseField('QueueId'),
          QueueConfigs: [
            {
              QueueReference: {
                QueueId: queues.spanish.getResponseField('QueueId'),
                Channel: 'VOICE'
              },
              Priority: 1,
              Delay: 0
            }
          ],
          MediaConcurrencies: [
            {
              Channel: 'VOICE',
              Concurrency: 1
            }
          ],
          Tags: {
            Language: 'Spanish',
            Environment: this.node.tryGetContext('environment') || 'dev',
            Project: 'ViStoCapital-UnifiedDialer'
          }
        },
        physicalResourceId: PhysicalResourceId.fromResponse('RoutingProfileId'),
      },
      policy: AwsCustomResourcePolicy.fromSdkCalls({
        resources: AwsCustomResourcePolicy.ANY_RESOURCE,
      }),
    });

    // Create English Routing Profile
    const englishProfile = new AwsCustomResource(this, 'EnglishRoutingProfile', {
      onCreate: {
        service: 'Connect',
        action: 'createRoutingProfile',
        parameters: {
          InstanceId: instanceId,
          Name: 'English-Agents-Profile',
          Description: 'Routing profile for English-speaking agents',
          DefaultOutboundQueueId: queues.english.getResponseField('QueueId'),
          QueueConfigs: [
            {
              QueueReference: {
                QueueId: queues.english.getResponseField('QueueId'),
                Channel: 'VOICE'
              },
              Priority: 1,
              Delay: 0
            }
          ],
          MediaConcurrencies: [
            {
              Channel: 'VOICE',
              Concurrency: 1
            }
          ],
          Tags: {
            Language: 'English',
            Environment: this.node.tryGetContext('environment') || 'dev',
            Project: 'ViStoCapital-UnifiedDialer'
          }
        },
        physicalResourceId: PhysicalResourceId.fromResponse('RoutingProfileId'),
      },
      policy: AwsCustomResourcePolicy.fromSdkCalls({
        resources: AwsCustomResourcePolicy.ANY_RESOURCE,
      }),
    });

    return {
      spanish: spanishProfile,
      english: englishProfile
    };
  }

  // private associateLambdaFunctions(instanceId: string, envConfig: any) {
  //   // We'll try to import Lambda ARNs from the SAM stack
  //   // These might not exist initially, so we'll make them optional

  //   try {
  //     const lookupLambdaArn = cdk.Fn.importValue('LookupSupabaseFunctionArn');
      
  //     new AwsCustomResource(this, 'LookupLambdaAssociation', {
  //       onCreate: {
  //         service: 'Connect',
  //         action: 'associateLambdaFunction',
  //         parameters: {
  //           InstanceId: instanceId,
  //           FunctionArn: lookupLambdaArn
  //         }
  //       },
  //       onDelete: {
  //         service: 'Connect',
  //         action: 'disassociateLambdaFunction',
  //         parameters: {
  //           InstanceId: instanceId,
  //           FunctionArn: lookupLambdaArn
  //         }
  //       },
  //       policy: AwsCustomResourcePolicy.fromSdkCalls({
  //         resources: AwsCustomResourcePolicy.ANY_RESOURCE,
  //       }),
  //     });
  //   } catch (error) {
  //     console.warn('Could not import Lambda ARNs from SAM stack - they may not be exported yet');
  //   }
  // }
} 