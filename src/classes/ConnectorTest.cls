@isTest public class ConnectorTest {
    
    public class TestMock_ok implements HttpCalloutMock {
		public HTTPResponse respond(HTTPRequest req) {
			string body=getResponse(req.getEndpoint());
            
            Httpresponse resp = new Httpresponse();
			resp.SetStatusCode(200);
            resp.setBody(body);
			return resp;
		}
        
        private string getResponse(string url) {
            
            Url u = new Url(url);
            Set<string> paramSet = new Set<string>(EncodingUtil.urlDecode(u.getQuery(), 'UTF-8').split('&'));
            Map<string, string> params = new Map<string, string>();
            for(string p : paramSet) {
                params.put(p.split('=')[0], p.split('=')[1]);
            }
            string ret = '';
            
            if(params.containsKey('rest_call')) {
                if(params.get('rest_call').equals('get_account_details'))
                    ret = '{"error_code": 0,"error_msg": "OK", "account_details": [ {' +
                        '"acct_no": 491069, "user_id": "3nss7ts6", "client_acct_id": "a2aP00000001FPZIA2", ' +
                        '"company_name": "Pinehurst Kia - Display_AdVantage","status_name": "ACTIVE" } ] } ';
                if(params.get('rest_call').equals('get_invoice_information'))
                    ret = '{"error_code": 0,"error_msg": "OK", "invoice_details": [ {' +
                        '"acct_no": 491069, "invoice_no": "1123344"} ] } ';
            }
            
            return ret;
        }
	}
    
    public static testMethod void providerTest () {
        AriaDataProvider prov = new AriaDataProvider();
        
        prov.getAuthenticationCapabilities();
        prov.getCapabilities();  
        
        DataSource.ConnectionParams params = new DataSource.ConnectionParams();
        params.username = 'user';
        params.password = 'pwd123';
        params.endpoint = 'http://localhost/test';
        
        prov.getConnection(params);
    }
    
    public static testMethod void connectorTest() {
        Test.setMock(HttpCalloutMock.class, new TestMock_ok());
        
        DataSource.ConnectionParams params = new DataSource.ConnectionParams();
        params.username = 'user';
        params.password = 'pwd123';
        params.endpoint = 'http://localhost/test';
        
        AriaConnector connector = new AriaConnector(params);
        
        connector.sync();
        
        DataSource.QueryContext ctx = new DataSource.QueryContext();
        ctx.tableSelection = new DataSource.TableSelection();
        ctx.tableSelection.filter = new DataSource.Filter();
        ctx.tableSelection.filter.columnName = 'test';
        ctx.tableSelection.filter.columnValue = 'test';
        ctx.tableSelection.tableSelected = 'accounts';
        connector.query(ctx);
        
        ctx.tableSelection.tableSelected = 'invoices';
        connector.query(ctx);
        
        DataSource.SearchContext sctx = new DataSource.SearchContext();
        sctx.tableSelections = new List<DataSource.TableSelection>();
        sctx.tableSelections.add(ctx.tableSelection);
        connector.search(sctx);
    }

    public static testMethod void dataClassesTest() {
        AriaTypes.acct_details_response val1 = new AriaTypes.acct_details_response();
        AriaTypes.invoice_info_response val2 = new AriaTypes.invoice_info_response();
        val2.error_code = val1.error_code;
        val2.error_message = val1.error_message;
    }
}