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

@sfdc:ServiceConfig {topic: config:getAsString("SF_CONTACT_TOPIC")}
service on sfdcEventListener1 {
    remote function onEvent(json cont) returns @tainted error? {
        io:StringReader sr = new (cont.toJsonString());
        json contact = check sr.readJson();
        string salutation = contact.sobject.Salutation.toString();
        string lastName = contact.sobject.LastName.toString();
        string firstName = contact.sobject.FirstName.toString();
        string mobilePhone = contact.sobject.MobilePhone.toString();
        string email = contact.sobject.Email.toString();
        string phone = contact.sobject.Phone.toString();
        string fax = contact.sobject.Fax.toString();
        string accountId = contact.sobject.AccountId.toString();
        string title = contact.sobject.Title.toString();
        string department = contact.sobject.Department.toString();
        json contactRecord = {
            Salutation: salutation,
            LastName: lastName,
            FirstName: firstName,
            MobilePhone: mobilePhone,
            Email: email,
            Phone: phone,
            Fax: fax,
            Title: title,
            Department: department
        };

        sfdc:SoqlResult resp = checkpanic baseClient2->getQueryResult("SELECT Id FROM Contact WHERE Email = '" + <@untainted>
        email + "'");
        if (resp.totalSize == 0) {
            string res = checkpanic baseClient2->createContact(<@untainted>contactRecord);

        } else {
            string id = resp.records[0]["Id"].toString();
            boolean res = checkpanic baseClient2->updateContact(id, <@untainted>contactRecord);
        }
    }
}
