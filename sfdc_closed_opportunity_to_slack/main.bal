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

@sfdc:ServiceConfig {topic: config:getAsString("SF_TASK_CREATION_TOPIC")}
service on sfdcEventListener1 {
    remote function onEvent(json res) returns @tainted error? {
        io:StringReader sr = new (res.toJsonString());
        json task = check sr.readJson();
        string id = task.sobject.Id.toString();
        string ownerId = task.sobject.OwnerId.toString();
        string subject = task.sobject.Subject.toString();
        string priority = task.sobject.Priority.toString();
        string activityDate = task.sobject.ActivityDate.toString();
        sfdc:SoqlResult resp = checkpanic baseClient->getQueryResult("SELECT Name FROM User WHERE Id = '" + <@untainted>
        ownerId + "'");
        string name = resp.records[0]["Name"].toString();

        slack:Message messageParams = {
            channelName:  config:getAsString("SLACK_CHANNEL"),
            text: "A new " + priority + " priority " + subject + " task is assigned to " + name + ". Due date is " + activityDate
        };

        string|slack:Error response = checkpanic slackClient->postMessage(messageParams);
    }
}
