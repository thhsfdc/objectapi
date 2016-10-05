public with sharing class case_api10 {
    
    public static api_v10.ResultClass insertCase(List<Sobject> ObjList) {
        api_v10.ResultClass result = new api_v10.ResultClass();
        List<database.SaveResult> DbsLst = database.insert(ObjList, false);
        for (database.SaveResult sr : DbsLst) {
            if (sr.isSuccess()) {
                api_v10.ResultItem ri = new api_v10.ResultItem();
                ri.RecordID = sr.getId();
                ri.RecordStatus = api_v10.Code_Success;
                result.ResultItemList.add(ri);
                System.debug('Successfully inserted record: ' + sr.getId());
            }
            else {
                for(Database.Error err : sr.getErrors()) {
                    api_v10.ResultItem ri = new api_v10.ResultItem();
                    ri.RecordErrorFields = String.join( err.getFields(), ',') ;
                    ri.RecordStatus = String.valueOf(err.getStatusCode());
                    result.ResultItemList.add(ri);
                    System.debug('The following error has occurred:' + err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Object fields that affected this error: ' + err.getFields());
                }
            }
        }
        return result;
    }
    
    public static api_v10.ResultClass updateCase(List<Sobject> ObjList) {
        api_v10.ResultClass result = new api_v10.ResultClass();
        List<database.SaveResult> DbsLst = database.update(ObjList, false);
        for (database.SaveResult sr : DbsLst) {
            if (sr.isSuccess()) {
                api_v10.ResultItem ri = new api_v10.ResultItem();
                ri.RecordID = sr.getId();
                ri.RecordStatus = api_v10.Code_Success;
                result.ResultItemList.add(ri);
                System.debug('Successfully upated record: ' + sr.getId());
            }
            else {
                for(Database.Error err : sr.getErrors()) {
                    api_v10.ResultItem ri = new api_v10.ResultItem();
                    ri.RecordErrorFields = String.join( err.getFields(), ',') ;
                    ri.RecordStatus = String.valueOf(err.getStatusCode());
                    result.ResultItemList.add(ri);
                    System.debug('The following error has occurred:' + err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Object fields that affected this error: ' + err.getFields());
                }
            }
        }
        return result;
    }
    
    public static api_v10.ResultClass selectfromCase(Set<String> FieldSet) {
        api_v10.ResultClass result = new api_v10.ResultClass();
        String QueryStr = api_v10.VerifiedQueryString(FieldSet, '', 'Case');
        result.ResultList = database.query(QueryStr);
        result.StatusCode = api_v10.Code_Success;
        result.StatusMessage = api_v10.Msg_Success;
        return result;
    }
}