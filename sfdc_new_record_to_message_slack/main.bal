import ballerina/io;
import ballerina/config;
import ballerinax/sfdc;
import ballerinax/slack;

sfdc:ListenerConfiguration listener1Config = {
    username: config:getAsString("SF1_USERNAME"),
    password: config:getAsString("SF1_PASSWORD")
};

listener sfdc:Listener sfdcEventListener1 = new (listener1Config);


string token = config:getAsString("SLACK_TOKEN");

slack:Configuration slackConfig1 = {oauth2Config: {accessToken: token}};

slack:Client slackClient = new (slackConfig1);

sfdc:SalesforceConfiguration sfConfig = {
    baseUrl: config:getAsString("SF1_EP_URL"),
    clientConfig: {
        accessToken: config:getAsString("SF1_ACCESS_TOKEN"),
        refreshConfig: {
            clientId: config:getAsString("SF1_CLIENT_ID"),
            clientSecret: config:getAsString("SF1_CLIENT_SECRET"),
            refreshToken: config:getAsString("SF1_REFRESH_TOKEN"),
            refreshUrl: config:getAsString("SF1_REFRESH_URL")
        }
    }
};

sfdc:BaseClient baseClient = new(sfConfig);

@sfdc:ServiceConfig {topic: config:getAsString("SF_CUSTOMER_CREATION_TOPIC")}
service on sfdcEventListener1 {
    remote function onEvent(json res) returns @tainted error? {
        io:StringReader sr = new (res.toJsonString());
        json task = check sr.readJson();
        string id = task.sobject.Id.toString();
        string name = task.sobject.Name.toString();
        string country = task.sobject.Country__c.toString();
     
        slack:Message messageParams = {
            channelName:  config:getAsString("SLACK_CHANNEL"),
            text: "A new customer from " + country + " , " + name + " is created."
        };

        string|slack:Error response = checkpanic slackClient->postMessage(messageParams);
    }
}
