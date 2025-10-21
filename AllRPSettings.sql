--Audit of all RP settings, mainly created by Jens
SELECT cl.name AS client,
    cl.id AS client_id,
    c.name AS community_name,
    c.id AS community_id,
    c.lead_management,
    c.rent_plus,
    cc.rent_charge_billed_by,
    cc.rent_charge_collected_by,
    cc.utility_charge_billed_by,
    cc.utility_charge_collected_by,
    cc.rent_plus_billed_by,
    cc.rent_plus_collected_by,
    cc.push_charges_active,
    cpcd.post_day,
    cpcd.charge_ledger_code,
    cpcd.refund_ledger_code,
    cpcd.charge_ledger_scan_code,
    cpcd.refund_ledger_scan_code,
    c.email_address,
    cpcd.rd_contact,
    cpcd.client_contact,
    c.product_id,
    csc.amount,
    csc.partner_split,
    csc.community_split,
    csc.rent_dynamics_split,
    csc.pm_company_split,
    cp.auto_enroll,
    CASE WHEN c.is_manual_subscription = true THEN 'Manual Subscription'
    WHEN cp.auto_enroll = true THEN 'Auto-Enrollment'
    ELSE 'Opt-In'
    END AS "Enrollment Model",
    cp.addendum_auto_enroll,
    CASE WHEN cp.auto_enroll = True THEN cp.auto_enroll_start_date ELSE NULL END AS auto_enroll_start_date,
    CASE WHEN cp.auto_enroll = True THEN cp.auto_enroll_portal_account_creation ELSE NULL END AS auto_enroll_portal_account_creation,
    t.path AS sign_up_template,
    cp.sign_up_url,
    cp.renewal_auto_enroll_after_days,
    cp.new_resident_auto_enroll_after_days,
    cp.addendum_auto_enroll,
    cp.lease_addendum_title,
    cp.manual_lease_title,
    cf.bulk_email,
    cf.credit_monitoring,
    cf.household,
    cf.disable_rentplus_price_visibility,
    cf.roommates_require_primary,
    cf.tradeline_rule_15th_is_delinquent,
    cf.self_cancel,
    cf.disable_self_signup,
    cf.trial,
    cf.conditional_membership_type,
    cf.same_day_refund,
    cf.homebody,
    cf.conditional_membership_type,
    CASE WHEN cf.credit_score_settings_id is not null then 'true' ELSE 'false'
    END credit_score,
    cf.renewal_split_audit
FROM community as c
        LEFT JOIN client as cl ON cl.id = c.client_id
        LEFT JOIN community_profile as cp ON cp.rd_community_id = c.id
        LEFT JOIN community_charge as cc ON cc.community_id = c.id
        LEFT JOIN community_push_charges_data as cpcd ON cpcd.id = cc.community_push_charges_data_id
        LEFT JOIN community_charge_splits as csc ON csc.community_id = c.id
        LEFT JOIN template as t ON t.id = cp.sign_up_template_id
        LEFT JOIN community_features as cf ON cf.rd_community_id = c.id
    WHERE --cl.account_manager_first_name = 'Bezait' AND cl.account_manager_last_name = 'Anbesse' --Allows users to search by CSM
        c.id in (43789, 44703, 41213, 42196, 44555, 44695, 44701, 44693, 44676, 44675, 44595) --Allows users to search by a list of community IDs
        --AND c.rent_plus = 'true'
        --AND c.lead_management = 'true'
        AND csc.contract_end is null
        AND csc.charge_code_type_id <> 2;