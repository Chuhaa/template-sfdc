import ballerina/config;
import ballerina/log;
import ballerinax/sfdc;

sfdc:SalesforceConfiguration sf1Config = {
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

sfdc:BaseClient baseClient1 = new(sf1Config);

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

sfdc:BaseClient baseClient2 = new(sf2Config);

public function main(){
    string queryStr = "SELECT Id, FirstName, LastName, Email, Phone, Company, Industry FROM Lead";
    
error|sfdc:BulkJob queryJob1 = baseClient1->creatJob("query", "Lead", "JSON");
    if (queryJob1 is sfdc:BulkJob) {
        error|sfdc:BatchInfo batch = queryJob1->addBatch(queryStr);
        if (batch is sfdc:BatchInfo) {
            string batchId = batch.id;
            var batchResult = queryJob1->getBatchResult(batchId);
            if (batchResult is json) {
                json[]|error batchResultArr = <json[]>batchResult;
                if(batchResultArr is json[]) {
                    foreach json lead in batchResultArr{
                        string lastName = lead.LastName.toString();
                        string firstName = lead.FirstName.toString();
                        string email = lead.Email.toString();
                        string phone = lead.Phone.toString();
                        string company = lead.Company.toString();
                        string industry = lead.Industry.toString();

                        json leadRecord = {
                            LastName: lastName,
                            FirstName: firstName,
                            Email: email,
                            Phone: phone,
                            Company: company,
                            Industry: industry
                        };                            
                        
                        sfdc:SoqlResult resp =  checkpanic baseClient2->getQueryResult("SELECT Id FROM Lead WHERE Email = '"+ <@untainted>  email +"'");
                        if(resp.totalSize == 0) {
                            string res =  checkpanic baseClient2->createLead(<@untainted> leadRecord);
                            log:print("Lead created for : " + email);


                        } else {
                            string id = resp.records[0]["Id"].toString();
                            boolean res = checkpanic baseClient2->updateLead(id, <@untainted> leadRecord);   
                            log:print("Lead updated for: " + email);
                        }   
                    }
                }
            }
            else {
                log:printError("Invalid Batch Result!");
            }           
        } else {
            log:printError(batch.message());
        }
    }
    else{
        log:printError(queryJob1.message());
    }
}

