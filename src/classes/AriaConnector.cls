// Salesforce Lightning Connector for Aria
global class AriaConnector extends DataSource.Connection {
    
    private string clientNo;
    private string authKey;
    private string ariaUrl;
    
    // ctor
    global AriaConnector(DataSource.ConnectionParams connectionParams){
		clientNo=connectionParams.username;
        authKey=connectionParams.password;
        ariaUrl=connectionParams.endpoint;
    }
    override global List<DataSource.Table> sync() {
        List<DataSource.Table> tables = new List<DataSource.Table>(); 
        
        // accounts
        List<DataSource.Column> acctCols = new List<DataSource.Column>();
        acctCols.add(DataSource.Column.text('acct_no', 30));
        acctCols.add(DataSource.Column.text('client_acct_id', 255));
        acctCols.add(DataSource.Column.text('company_name', 255));
        
        acctCols.add(DataSource.Column.text('ExternalId', 30));
        acctCols.add(DataSource.Column.url('DisplayUrl'));
        tables.add(DataSource.Table.get('accounts', 'acct_no', acctCols));
        
        // invoices
        List<DataSource.Column> invCols = new List<DataSource.Column>();
        invCols.add(DataSource.Column.text('invoice_no', 30));
        invCols.add(DataSource.Column.text('acct_no', 30));
        invCols.add(DataSource.Column.get('from_date', 'from_date', '', false, false, DataSource.DataType.DATETIME_TYPE, 8));
        invCols.add(DataSource.Column.get('to_date', 'to_date', '', false, false, DataSource.DataType.DATETIME_TYPE, 8));
        invCols.add(DataSource.Column.number('credit', 10, 4));
        invCols.add(DataSource.Column.number('debit', 10, 4));
        
        invCols.add(DataSource.Column.externalLookup('aria_account', 'accounts__x'));
        
        invCols.add(DataSource.Column.text('ExternalId', 30));
        invCols.add(DataSource.Column.url('DisplayUrl'));
        tables.add(DataSource.Table.get('invoices', 'invoice_no', invCols));
        
        return tables;
    }
    
    // get data(soql)
    override global DataSource.TableResult query(DataSource.QueryContext ctx) {
        return DataSource.TableResult.get(ctx, getAllRows(ctx));
    }
    
    // get data (sosl)
    override global List<DataSource.TableResult> search(DataSource.SearchContext ctx) {        
        List<DataSource.TableResult> results = new List<DataSource.TableResult>();
        /*for (DataSource.TableSelection tableSelection : ctx.tableSelections) {
            results.add(DataSource.TableResult.get(tableSelection, getAllRows(ctx)));
        }*/
        return results;
    }

    private List<Map<String, Object>> getAllRows (DataSource.QueryContext ctx) {
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
		system.debug('---------- tableSelected: ' + ctx.tableSelection.tableSelected);
        system.debug('---------- filter: ' + ctx.tableSelection.filter);
        system.debug('---------- order: ' + ctx.tableSelection.order);
        if(ctx.tableSelection.tableSelected == 'accounts')
        	rows.addAll(getAccountRows(ctx.tableSelection.filter, ctx.tableSelection.order));
        if(ctx.tableSelection.tableSelected == 'invoices')
        	rows.addAll(getInvoicesRows(ctx.tableSelection.filter, ctx.tableSelection.order));
   
        return rows;
    }
    

    private List<Map<string, object>> getAccountRows(DataSource.Filter filter, List<DataSource.Order> order){
        string filterQuery = '';
        if(filter != null) {
        	if(filter.columnName == 'ExternalId') filter.columnName = 'acct_no';
            if(filter.columnName != null)
        		filterQuery = filter.columnName + ' ' + parseFilterType(filter.type) + ' ' + filter.columnValue;
        }
        
        HttpResponse response = getAccountsRest(filterQuery);
        AriaTypes.acct_details_response accts = (AriaTypes.acct_details_response)JSON.deserialize(response.getBody(), AriaTypes.acct_details_response.class);
        
        List<Map<string, object>> retVal = new List<Map<string, object>>();
        for(AriaTypes.accountDetails det : accts.account_details){
            Map<string, object> ob = new Map<string, object>();
            ob.put('acct_no', det.acct_no);
            ob.put('client_acct_id', det.client_acct_id);
            ob.put('company_name', det.company_name);
            ob.put('ExternalId', det.acct_no);
            ob.put('DisplayUrl', 'http://yandex.ru');
            retVal.add(ob);
        }
        
        return retVal;
    }
    
    private List<Map<string, object>> getInvoicesRows(DataSource.Filter filter, List<DataSource.Order> order){
        string filterQuery = '';
        if(filter != null) {
        	if(filter.columnName == 'ExternalId') filter.columnName = 'invoice_no';
            if(filter.columnName == 'aria_account') filter.columnName = 'acct_no';
            if(filter.columnName != null)
        		filterQuery = filter.columnName + ' ' + parseFilterType(filter.type) + ' ' + filter.columnValue;
        }
        
        HttpResponse response = getInvoicesRest(filterQuery);
        AriaTypes.invoice_info_response invoices = (AriaTypes.invoice_info_response)JSON.deserialize(response.getBody(), AriaTypes.invoice_info_response.class);
        
        List<Map<string, object>> retVal = new List<Map<string, object>>();
        for(AriaTypes.invoiceInformation det : invoices.invoice_details) {
            Map<string, object> ob = new Map<string, object>();
			ob.put('invoice_no', det.invoice_no);
            ob.put('acct_no', det.acct_no);
            ob.put('from_date', det.from_date);
            ob.put('to_date', det.to_date);
            ob.put('credit', det.credit);
            ob.put('debit', det.debit);
            ob.put('ExternalId', det.invoice_no);
            ob.put('aria_account', det.acct_no);
            ob.put('DisplayUrl', 'http://yandex.ru');
            retVal.add(ob);
        }
        
        return retVal;
    }
    
    private string parseFilterType(DataSource.FilterType t) {
        if(t == DataSource.FilterType.EQUALS) return '=';
        if(t == DataSource.FilterType.GREATER_THAN) return '>';
        if(t == DataSource.FilterType.LESS_THAN) return '<';
        
        return '=';
    }
    
        
    // Helper methods
    private HttpResponse getAccountsRest(string filterQuery) {
        if(string.isEmpty(filterQuery)) filterQuery = 'acct_no is not null';
        string params='rest_call=get_account_details&query_string=' + EncodingUtil.urlEncode(filterQuery, 'UTF-8');
        return makeGetCallout(params);
    }
    private HttpResponse getInvoicesRest(string filterQuery) {
        if(string.isEmpty(filterQuery)) filterQuery = 'acct_no is not null limit 100';
        string params='rest_call=get_invoice_information&query_string=' + EncodingUtil.urlEncode(filterQuery, 'UTF-8');
        return makeGetCallout(params);
    }
    // Make a GET callout
     private HttpResponse makeGetCallout(string params) {
         
         string commonParams = 'output_format=json&' + 
             'client_no=' + clientNo + '&' +
             'auth_key=' + authKey;
         
         HttpResponse response;
         Http http = new Http(); 
         HttpRequest req = new HttpRequest(); 
         req.setEndpoint(ariaUrl + '?' + commonParams + '&' + params);
         req.setMethod('GET');
         
         response = Http.send(req);
         return response;
     }
}