CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    TYPES: tt_header TYPE STANDARD TABLE OF zfeedbackh_050 WITH EMPTY KEY,
           tt_items  TYPE STANDARD TABLE OF zfeedbacki_050 WITH EMPTY KEY.

    TYPES: BEGIN OF ty_buffer,
             header TYPE tt_header,
             items  TYPE tt_items,
             delete_header TYPE tt_header,
             delete_items  TYPE tt_items,
           END OF ty_buffer.

    CLASS-DATA mt_buffer TYPE ty_buffer.
ENDCLASS.

CLASS lhc_Feedback DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Feedback
      RESULT result.
    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE Feedback.
    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE Feedback.
    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE Feedback.
    METHODS read FOR READ
      IMPORTING keys FOR READ Feedback RESULT result.
    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK Feedback.
    METHODS rba_Items FOR READ
      IMPORTING keys_rba FOR READ Feedback\_Items FULL result_requested RESULT result LINK association_links.
    METHODS cba_Items FOR MODIFY
      IMPORTING entities_cba FOR CREATE Feedback\_Items.
ENDCLASS.

CLASS lhc_Feedback IMPLEMENTATION.
  METHOD get_global_authorizations.
  IF requested_authorizations-%create = if_abap_behv=>mk-on.
    result-%create = if_abap_behv=>auth-allowed.
  ENDIF.
  IF requested_authorizations-%update = if_abap_behv=>mk-on.
    result-%update = if_abap_behv=>auth-allowed.
  ENDIF.
  IF requested_authorizations-%delete = if_abap_behv=>mk-on.
    result-%delete = if_abap_behv=>auth-allowed.
  ENDIF.
ENDMETHOD.


  METHOD create.
  DATA: lv_timestamp TYPE timestampl.
  GET TIME STAMP FIELD lv_timestamp.

  LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_entity>).
    INSERT VALUE #(
      fb_uuid         = <ls_entity>-FeedbackUUID
      customer_id     = <ls_entity>-CustomerID
      customer_name   = <ls_entity>-CustomerName
      overall_rating  = <ls_entity>-OverallRating
      created_by      = sy-uname
      created_at      = lv_timestamp
      last_changed_by = sy-uname   " ← ADD THIS (mandatory for draft)
      last_changed_at = lv_timestamp
    ) INTO TABLE lcl_buffer=>mt_buffer-header.
  ENDLOOP.
ENDMETHOD.

  METHOD update.
  DATA: lv_timestamp TYPE timestampl.
  GET TIME STAMP FIELD lv_timestamp.

  LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_entity>).
    SELECT SINGLE * FROM zfeedbackh_050
      WHERE fb_uuid = @<ls_entity>-FeedbackUUID
      INTO @DATA(ls_db).

    IF sy-subrc = 0.
      IF <ls_entity>-%control-CustomerName = if_abap_behv=>mk-on.
        ls_db-customer_name = <ls_entity>-CustomerName.
      ENDIF.
      IF <ls_entity>-%control-OverallRating = if_abap_behv=>mk-on.
        ls_db-overall_rating = <ls_entity>-OverallRating.
      ENDIF.

      ls_db-last_changed_by = sy-uname.
      ls_db-last_changed_at = lv_timestamp.

      INSERT ls_db INTO TABLE lcl_buffer=>mt_buffer-header.
    ENDIF.
  ENDLOOP.
ENDMETHOD.

  METHOD delete.
  LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).
    INSERT VALUE #( fb_uuid = <ls_key>-%key-FeedbackUUID )
      INTO TABLE lcl_buffer=>mt_buffer-delete_header.
  ENDLOOP.
ENDMETHOD.

  METHOD read.
  IF keys IS NOT INITIAL.
    SELECT FROM zfeedbackh_050
      FIELDS fb_uuid         AS FeedbackUUID,
             customer_id     AS CustomerID,
             customer_name   AS CustomerName,
             overall_rating  AS OverallRating,
             created_by      AS CreatedBy,
             created_at      AS CreatedAt,
             last_changed_by AS LastChangedBy,
             last_changed_at AS LastChangedAt
      FOR ALL ENTRIES IN @keys
      WHERE fb_uuid = @keys-%key-FeedbackUUID
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDIF.
ENDMETHOD.

  METHOD lock.
    " For unmanaged, you would typically call an ENQUEUE Function Module here
  ENDMETHOD.

  METHOD rba_Items.
  IF keys_rba IS NOT INITIAL.
    SELECT item_uuid   AS ItemUUID,
           parent_uuid AS ParentUUID,
           feedback_cat AS Category,
           rating       AS Rating,
           remarks      AS Remarks
      FROM zfeedbacki_050
      FOR ALL ENTRIES IN @keys_rba
      WHERE parent_uuid = @keys_rba-FeedbackUUID
      INTO CORRESPONDING FIELDS OF TABLE @result.  " ← populate result

    " Also populate association_links
    LOOP AT result ASSIGNING FIELD-SYMBOL(<ls_item>).
      INSERT VALUE #(
        source-%key-FeedbackUUID = <ls_item>-ParentUUID
        target-%key-ItemUUID     = <ls_item>-ItemUUID
      ) INTO TABLE association_links.
    ENDLOOP.
  ENDIF.
ENDMETHOD.

  METHOD cba_Items.
    LOOP AT entities_cba ASSIGNING FIELD-SYMBOL(<ls_cba>).
      LOOP AT <ls_cba>-%target ASSIGNING FIELD-SYMBOL(<ls_item>).
        INSERT VALUE #(
          item_uuid    = <ls_item>-ItemUUID
          parent_uuid  = <ls_cba>-FeedbackUUID
          feedback_cat = <ls_item>-Category
          rating       = <ls_item>-Rating
          remarks      = <ls_item>-Remarks
        ) INTO TABLE lcl_buffer=>mt_buffer-items.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_Items DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS update FOR MODIFY IMPORTING entities FOR UPDATE Items.
    METHODS delete FOR MODIFY IMPORTING keys FOR DELETE Items.
    METHODS read FOR READ IMPORTING keys FOR READ Items RESULT result.
ENDCLASS.

CLASS lhc_Items IMPLEMENTATION.
  METHOD update.
  LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_item_update>).
    SELECT SINGLE * FROM zfeedbacki_050
      WHERE item_uuid = @<ls_item_update>-%key-ItemUUID
      INTO @DATA(ls_item_db).

    IF sy-subrc = 0.
      IF <ls_item_update>-%control-Category = if_abap_behv=>mk-on.
        ls_item_db-feedback_cat = <ls_item_update>-Category.
      ENDIF.
      IF <ls_item_update>-%control-Rating = if_abap_behv=>mk-on.
        ls_item_db-rating = <ls_item_update>-Rating.
      ENDIF.
      IF <ls_item_update>-%control-Remarks = if_abap_behv=>mk-on.
        ls_item_db-remarks = <ls_item_update>-Remarks.
      ENDIF.

      INSERT ls_item_db INTO TABLE lcl_buffer=>mt_buffer-items.
    ENDIF.
  ENDLOOP.
ENDMETHOD.

  METHOD delete.
  LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).
    INSERT VALUE #( item_uuid = <ls_key>-%key-ItemUUID )
      INTO TABLE lcl_buffer=>mt_buffer-delete_items.
  ENDLOOP.
ENDMETHOD.

METHOD read.
  IF keys IS NOT INITIAL.
    SELECT * FROM zfeedbacki_050
      FOR ALL ENTRIES IN @keys
      WHERE item_uuid = @keys-%key-ItemUUID
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDIF.
ENDMETHOD.
ENDCLASS.

CLASS lsc_ZI_FEEDBACKH_050 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS finalize REDEFINITION.
    METHODS check_before_save REDEFINITION.
    METHODS save REDEFINITION.
    METHODS cleanup REDEFINITION.
ENDCLASS.

CLASS lsc_ZI_FEEDBACKH_050 IMPLEMENTATION.
  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
    " Handle Header Changes
    IF lcl_buffer=>mt_buffer-header IS NOT INITIAL.
      MODIFY zfeedbackh_050 FROM TABLE @lcl_buffer=>mt_buffer-header.
    ENDIF.

    " Handle Item Changes
    IF lcl_buffer=>mt_buffer-items IS NOT INITIAL.
      MODIFY zfeedbacki_050 FROM TABLE @lcl_buffer=>mt_buffer-items.
    ENDIF.

    " Handle Deletions
    IF lcl_buffer=>mt_buffer-delete_header IS NOT INITIAL.
      DELETE zfeedbackh_050 FROM TABLE @lcl_buffer=>mt_buffer-delete_header.
    ENDIF.

    IF lcl_buffer=>mt_buffer-delete_items IS NOT INITIAL.
      DELETE zfeedbacki_050 FROM TABLE @lcl_buffer=>mt_buffer-delete_items.
    ENDIF.
  ENDMETHOD.

  METHOD cleanup.
    CLEAR lcl_buffer=>mt_buffer.
  ENDMETHOD.
ENDCLASS.
