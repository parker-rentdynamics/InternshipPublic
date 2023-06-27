SELECT DISTINCT
    cg.Name as 'Community Name',
    cg.ID AS 'Community ID',
    s.ID as 'Service ID',
    s.Name as 'Service Name',
    CASE --Case is always 'true'; tables do not contain data for inactive services
        WHEN communityService.ServiceID IS NULL THEN 'FALSE'
        ELSE 'TRUE'
    END as 'Active'
FROM Service AS s WITH (NOLOCK)
---- Add Community Group ID and Service ID from Community Group Service dataset ----
LEFT JOIN (
    SELECT cgs.CommunityGroupID, cgs.ServiceID
    FROM CommunityGroupService AS cgs WITH(NOLOCK)
    -- NOTE: Use WHERE CommunityGroup.ClientID = 4 to obtain all community data for client?
    --WHERE cgs.CommunityGroupID = 5667
   ) communityService ON communityService.ServiceID = s.ID
---- Add community name column from Community Group Dataset ----
LEFT JOIN CommunityGroup AS cg WITH(NOLOCK)
    ON cg.ID = communityService.CommunityGroupID
-- Add is community active data from Community Application dataset ----
LEFT JOIN CommunityApplication as ca WITH(NOLOCK)
    ON ca.CommunityID = cg.ID
---- Restrict table data to where community active is true and specified client ID
-- Adding WHERE statement here reverts to only active services?
  WHERE cg.ClientID = 4
--AND ca.IsActive = 1
ORDER BY cg.Name -- Service IDs out of order;
--ordering by NULL name or ID will cause inactive services to bunch up in list out of order
--Need to fill in null spaces with case statement in sub queries
