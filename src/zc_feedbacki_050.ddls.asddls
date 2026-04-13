@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'Consumption Item'
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true
define view entity ZC_FEEDBACKI_050 
as projection on ZI_FEEDBACKI_050
{
  key ItemUUID,
      ParentUUID,
      
      @Search.defaultSearchElement: true
      Category,
      
      Rating,
      Remarks,
      
      /* Associations */
      _Header : redirected to parent ZC_FEEDBACKH_050
}
