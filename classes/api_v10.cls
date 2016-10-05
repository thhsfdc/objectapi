public class api_v10 {
    
    public static final String Code_Success = '200';
    public static final String Code_Error = '500';
    public static final String Msg_Error = 'an error occured / nothing executed';
    public static final String Msg_Success = 'Operation successfully executed';
    
    public class RecordLineItemClass{
        public string fieldName = '';
        public string fieldValue = '';
        public string fieldType = '';  // e.g. String / Number / Boolean
    }
    
    public class RecordListClass{
        public List<RecordLineItemClass> RecordList = new List<RecordLineItemClass>();
        public String ObjectName = '';
    }
    
    public class ResultItem{
        public string RecordID = '';
        public string RecordStatus = '';
        public string RecordErrorFields = '';
    }
    
    public class ResultClass{
        public string StatusCode = Code_Error; 
        public string StatusMessage = Msg_Error; 
        public List<ResultItem> ResultItemList = new List<ResultItem>(); 
        public List<Sobject> ResultList = new List<Sobject>();     
    }
    
    public class FieldClass{  // FieldMetadata description entity
        public string fieldName = '';
        public boolean IsMandatory = false;
        public string fieldType = '';  // e.g. String / Number / Boolean
    }
    
    public class ClObjectFields {
        public String objName;
        public Set<FieldClass> objFields;
        // public Set<String> objFields;  // version 0.1 
    }
    
    public static String SpecificQueryString(List<String> FieldList, String ConditionString,  String ObjectName ) {
        api_v10.ResultClass result = new api_v10.ResultClass();
        String queryStr='select ' + String.join( FieldList, ',') ;
        queryStr =+'  from   ' + ObjectName;
        queryStr =+ (ConditionString.length() > 0 ) ? '  where  ' + ConditionString : '' ;
        system.debug('Query String = ' + queryStr);
        return queryStr;
    }
    
    public static ClObjectFields getFieldsfromObject(String ObjectName) {
        system.debug('## (getFieldsfromObject) - ObjectName:'+ObjectName);
        Map<String, Schema.DescribeSObjectResult> ObjectMap = new Map<String,Schema.DescribeSObjectResult>();
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        ClObjectFields  objectFields = new ClObjectFields();
        objectFields.objName = ObjectName;
        objectFields.objFields = new Set<FieldClass>(); // new Set<String>();
        Set <String> oSet = new Set<String>();
        for (String os : gd.keyset()) {
            if (os.toLowerCase().contains(ObjectName.toLowerCase())  ) {
                ObjectMap.put(os, gd.get(os).getdescribe());
            } // if
        } // for
        system.debug('## ObjectMap:'+ObjectMap);
        system.debug('## ValidationSet:'+objectFields);
        for (String os :ObjectMap.keyset() ) {
            Map<String, Schema.SObjectField>  fieldMap =  new Map<String, Schema.SObjectField>();  // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_methods_system_fields_describe.htm#apex_methods_system_fields_describe
            fieldMap =gd.get(os).getDescribe().fields.getMap();
            for(Schema.SObjectField sfield : fieldMap.Values()){
                schema.describefieldresult dfield = sfield.getDescribe();
                if ( dfield.isAccessible()) {
                    FieldClass singleField = new FieldClass();  // new v.02
                    singleField.fieldName = dfield.getname().toLowerCase();   // new v.02  s
                    singleField.IsMandatory = !dfield.isNillable();  // isMandatory means - field is not Nillable
                    singleField.fieldType = string.valueOf(dfield.getType()).toLowerCase();   // string represensation of field type
                    // one could add more checks here following the getdescribe - update the FieldClass as needed
                    // e.g. calculated fields, parent fields etc
                    objectFields.objFields.add(singleField);
                    // objectFields.objFields.add(dfield.getname());
                }
            }
        }
        return objectFields;
    }
    
    public static String VerifiedQueryString(Set<String> FieldList, String ConditionString,  String ObjectName ) {
        api_v10.ResultClass result = new api_v10.ResultClass();
        ClObjectFields ObjectFields=getFieldsfromObject(ObjectName);
        Set<String> ObjectFieldSet = new Set<String>();
        for (FieldClass f : ObjectFields.objFields ) {  // helper to built a "Set" object with fields
            ObjectFieldSet.add(f.fieldname);
        }
        List<String> FieldListVerified = new List<String>();
        for (string fieldname : FieldList) {
            if (ObjectFieldSet.contains(fieldname) ) 
                FieldListVerified.add(fieldname);
            else 
                system.debug('VerifiedQueryString excluded field:'+fieldname);
        }
        String queryStr='select ' + String.join( FieldListVerified, ',') ;
        queryStr =+'  from   ' + ObjectName;
        queryStr =+ (ConditionString.length() > 0 ) ? '  where  ' + ConditionString : '' ;
        system.debug('Query String = ' + queryStr);
        return queryStr;
    }
    
    public static api_v10.ResultClass insertRecords(RecordListClass Records) {
        api_v10.ResultClass result = new api_v10.ResultClass();
        // check fields to be available
        // 1 - get fields from current object definition
        ClObjectFields ObjectFields=getFieldsfromObject(Records.ObjectName);
        Set<String> ObjectFieldSet = new Set<String>();
        for (FieldClass f : ObjectFields.objFields ) {  // helper to built a "Set" object with fields
            ObjectFieldSet.add(f.fieldname);
        }
        // 2 - check and create verfied list
        List<RecordLineItemClass> FieldListVerified = new List<RecordLineItemClass>();
        Set<String> FieldSetVerified = new Set<String>();  // set fo easier handling of above complex list
        for (RecordLineItemClass record : Records.RecordList) {
            if (ObjectFieldSet.contains(record.fieldname) ) {
                FieldListVerified.add(record);
                FieldSetVerified.add(record.fieldname);
            }
            else 
                system.debug('insertRecords - Verify fields excluded field:'+record);
        }
        // 3 - check mandatory fields from object
        for (RecordLineItemClass record : Records.RecordList ) { // run thru all records from Records
            for (FieldClass f : ObjectFields.objFields ) { 
                
                if (f.IsMandatory 
                    || ! FieldSetVerified.contains(f.fieldname)
                   ) {
                       RecordLineItemClass r= new RecordLineItemClass();
                       record.fieldname = f.fieldname;
                       record.fieldType = f.fieldType;
                       record.fieldValue = (f.fieldType.containsIgnoreCase('string')) ? ' ' : null ;
                       record.fieldValue = (f.fieldType.containsIgnoreCase('boolean')) ? 'false' : null ;
                       record.fieldValue = (f.fieldType.containsIgnoreCase('Integer ')) ? '0' : null ;
                       FieldListVerified.add(r); 
                   }
            }
        }
        // 4 - built DML insert  
        // List<Sobject> ObjectList = List<Sobject>();
        for ( RecordLineItemClass r : FieldListVerified){
           // Object o = new Object();
            //o.put(r.fieldname, r.fieldvalue);
        }
        
        //
        return result;
    }
    
}