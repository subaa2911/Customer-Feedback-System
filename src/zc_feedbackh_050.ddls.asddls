@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'Consumption Header'
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true
define root view entity ZC_FEEDBACKH_050 
provider contract transactional_query
  as projection on ZI_FeedbackH_050
{
  key FeedbackUUID,
  
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      CustomerID,
      
      @Search.defaultSearchElement: true
      CustomerName,
      
      OverallRating,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      
      /* Associations */
      _Items : redirected to composition child ZC_FEEDBACKI_050
}
