@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface Header'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_FeedbackH_050 as select from zfeedbackh_050
composition [0..*] of ZI_FEEDBACKI_050 as _Items
{
  key fb_uuid         as FeedbackUUID,
      customer_id     as CustomerID,
      customer_name   as CustomerName,
      overall_rating  as OverallRating,

      @Semantics.user.createdBy: true
      created_by      as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at      as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at as LastChangedAt,

      /* Associations */
      _Items
}
