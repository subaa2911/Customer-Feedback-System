@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface Item'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_FEEDBACKI_050 as select from zfeedbacki_050
association to parent ZI_FeedbackH_050 as _Header on $projection.ParentUUID = _Header.FeedbackUUID
{
  key item_uuid    as ItemUUID,
      parent_uuid  as ParentUUID,
      feedback_cat as Category,
      rating       as Rating,
      remarks      as Remarks,

      /* Associations */
      _Header
}
