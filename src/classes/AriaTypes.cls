global class AriaTypes {
    
    public abstract class GenericResponse {
        public integer error_code;
        public string error_message;
		
		public void age;
    }
    
    public class accountDetails {
        public string acct_no;
        public string client_acct_id;
        public string company_name;
    }
    
    public class acct_details_response extends GenericResponse {
        public List<accountDetails> account_details;
        public acct_details_response() { account_details = new List<accountDetails>(); }
    }
    
    public class invoiceInformation {
        public string invoice_no;
        public string acct_no;
        public string from_date;
        public string to_date;
        public double credit;
        public double debit;
    }
    
    public class invoice_info_response extends GenericResponse {
        public List<invoiceInformation> invoice_details;
        public invoice_info_response() { invoice_details = new List<invoiceInformation>(); }
    }

}