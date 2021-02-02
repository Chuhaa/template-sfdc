import ballerina/io;
import ballerina/config;
import ballerinax/sfdc;

sfdc:ListenerConfiguration listener1Config = {
    username: config:getAsString("SF1_USERNAME"),
    password: config:getAsString("SF1_PASSWORD")
};

listener sfdc:Listener sfdcEventListener1 = new (listener1Config);

sfdc:SalesforceConfiguration sf2Config = {
    baseUrl: config:getAsString("SF2_EP_URL"),
    clientConfig: {
        accessToken: config:getAsString("SF2_ACCESS_TOKEN"),
        refreshConfig: {
            clientId: config:getAsString("SF2_CLIENT_ID"),
            clientSecret: config:getAsString("SF2_CLIENT_SECRET"),
            refreshToken: config:getAsString("SF2_REFRESH_TOKEN"),
            refreshUrl: config:getAsString("SF2_REFRESH_URL")
        }
    }
};

sfdc:BaseClient baseClient2 = new (sf2Config);

@sfdc:ServiceConfig {topic: config:getAsString("SF_LEAD_BROADCAST_TOPIC")}
service on sfdcEventListener1 {
    remote function onEvent(json val) returns @tainted error? {
        io:StringReader sr = new (val.toJsonString());
        json lead = check sr.readJson();
        string lastName = lead.sobject.LastName.toString();
        string firstName = lead.sobject.FirstName.toString();
        string company = lead.sobject.Company.toString();
        string email = lead.sobject.Email.toString();
        string phone = lead.sobject.Phone.toString();
        string industry = lead.sobject.Industry.toString();
        string leadSource = lead.sobject.LeadSource.toString();
        json leadRecord = {
            LastName: lastName,
            FirstName: firstName,
            Company: company,
            Email: email,
            Phone: phone,
            Industry: industry,
            LeadSource: leadSource
        };

        sfdc:SoqlResult resp = checkpanic baseClient2->getQueryResult("SELECT Id FROM Lead WHERE Email = '" + <@untainted>
        email + "'");
        if (resp.totalSize == 0) {        
            string res = checkpanic baseClient2->createLead(<@untainted>leadRecord);
        } else {
            string id = resp.records[0]["Id"].toString();
            boolean res = checkpanic baseClient2->updateLead(id, <@untainted>leadRecord);
        }
    }
}
