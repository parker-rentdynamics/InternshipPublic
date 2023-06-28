--MASTER COMMUNITY INFO (RR1)--
SELECT DISTINCT cl.ID                                                          AS "ClientID",
                cl.OrganizationName                                              AS "ClientName",
                c.ID                                                      AS "CommunityID",
                c.CommunityName                                                  AS "CommunityName",
                pms.Name                                                          AS "PMSystem",
                c.CreatedOn                                                      AS "CreatedDate",
                UnitCount,
                a.AddressLine1 AS "Street",
                a.City AS "City",
                s.Name AS "State",
                a.Zip AS "Zip",
                CONCAT(RPA.FirstName, ' ', RPA.LastName)                   AS "RentPlusAM",
                CONCAT(LMA.FirstName, ' ', LMA.LastName)                   AS "LeadMgtAM",
                CASE WHEN CRP.equifax_active = 'true' THEN 1 ELSE 0 END    AS "EquifaxActive",
                CASE WHEN CRP.transunion_active = 'true' THEN 1 ELSE 0 END AS "TransunionActive",
                CASE WHEN CRP.experian_active = 'true' THEN 1 ELSE 0 END   AS "ExperianActive",
CASE
           WHEN ComType.type_checkerr BETWEEN 1 AND 99 THEN 'Affordable'
           WHEN ComType.type_checkerr BETWEEN 100 AND 999 THEN 'Market'
           WHEN ComType.type_checkerr >= 1000 THEN 'Student'
           WHEN ComType.type_checkerr = 0 THEN 'Market'
           WHEN ComType.type_checkerr < 0 THEN 'CreditBuilder' END as "CommunityType",
                CASE
                    WHEN RI.ID = 2 THEN 1
                    WHEN RI.ID IS NULL OR RI.ID = 1 THEN 0
                    END                                                    AS "IsCreditBuilder",
                CASE
                    WHEN CC.isActive = 1
                        AND CC.MostRecentContact > GETDATE() - 30
                        THEN 1
                    ELSE 0
                    END                                                             'CCContactWithin30Days',
                CASE
                    WHEN CallCenterCalls.Name IS NOT NULL THEN 1
                    ELSE 0
                    END                                                             'Contact Center Calls',
                CASE
                    WHEN CallCenterTexting.Name IS NOT NULL THEN 1
                    ELSE 0
                    END                                                             'Contact Center Texting',
                CASE
                    WHEN CallCenterEmails.Name IS NOT NULL THEN 1
                    ELSE 0
                    END                                                             'Contact Center Emails',
                CASE
                    WHEN CallCenterFollowUp.Name IS NOT NULL THEN 1
                    ELSE 0
                    END                                                             'Contact Center Follow Ups'
FROM Community c WITH (NOLOCK)
         JOIN Client cl WITH (NOLOCK) ON cl.ID = c.ClientID
         JOIN CommunityApplication ca WITH (NOLOCK) ON c.ID = ca.CommunityID
         LEFT JOIN CommunityReportingProfile crp WITH (NOLOCK) ON c.ID = CRP.community_id
         LEFT JOIN ClientAccountManager CAM WITH (NOLOCK) ON CAM.ClientID = cl.ID
         LEFT JOIN Agent RPA WITH (NOLOCK) ON RPA.ID = CAM.RentPlusAgentID
         LEFT JOIN Agent LMA WITH (NOLOCK) ON LMA.ID = CAM.LeadManagementAgentID
         LEFT JOIN CommunityCommunityType cct WITH (NOLOCK) ON cct.CommunityID = c.ID
         LEFT JOIN CommunityType ct WITH (NOLOCK) ON ct.ID = cct.CommunityTypeID
         JOIN PMSystemConnectionData pmc WITH (NOLOCK) ON pmc.ID = c.PropertyManagementRetrieverDataID
         JOIN PMSystemType pms WITH (NOLOCK) ON pmc.PMSystemTypeID = pms.ID
         LEFT JOIN CommunityCommunityGroup ccg WITH (NOLOCK) ON ccg.CommunityID = c.id
         LEFT JOIN CommunityGroup cg WITH (NOLOCK) ON cg.id = ccg.CommunityGroupID
         JOIN Address a WITH (NOLOCK) ON a.ID = c.AddressID
         JOIN State s WITH (NOLOCK) ON s.ID = a.StateID
         LEFT JOIN ResManConnectionData RCD
    WITH (NOLOCK) ON RCD.PMSystemConnectionDataID = pmc.ID
         LEFT JOIN ResManInterface RI
    WITH (NOLOCK) ON RI.ID = RCD.ResManInterfaceID
        OUTER APPLY(SELECT c1.ID,
             c1.ClientID,
             SUM(case WHEN RI1.ID = 2 THEN -10000
                     WHEN ct1.ID = 1 THEN 10
                     WHEN ct1.ID = 2 THEN 100
                     WHEN ct1.ID = 3 THEN 1000
                     WHEN ct1.ID >= 4 THEN 1
                     WHEN ct1.ID IS NULL THEN 0 END) as "type_checkerr"
      FROM Community c1 WITH (NOLOCK)
            LEFT JOIN CommunityCommunityType cct1 WITH (NOLOCK) ON cct1.CommunityID = c1.ID
               LEFT JOIN CommunityType ct1 WITH (NOLOCK) ON ct1.ID = cct1.CommunityTypeID
            JOIN PMSystemConnectionData pmc1 WITH (NOLOCK) ON pmc1.ID = c1.PropertyManagementRetrieverDataID
                LEFT JOIN ResManConnectionData RCD1 WITH (NOLOCK) ON RCD1.PMSystemConnectionDataID = pmc1.ID
                LEFT JOIN ResManInterface RI1 WITH (NOLOCK) ON RI1.ID = RCD1.ResManInterfaceID
     WHERE c1.ID = c.ID
      GROUP BY c1.ID, c1.ClientID) as "ComType"
        OUTER APPLY (SELECT u.CommunityID, COUNT(u.ID) AS "UnitCount"
                    FROM Unit u WITH (NOLOCK)
                    WHERE u.CommunityID = c.ID
                    GROUP BY u.CommunityID) AS "Unit"
         OUTER APPLY (SELECT TOP 1 s.Name
                      FROM Service s WITH (NOLOCK)
                               JOIN CommunityGroupService cgs WITH (NOLOCK) ON cgs.ServiceID = s.ID
                      WHERE cgs.CommunityGroupID = cg.ID
                        AND s.id = 7) AS CallCenterCalls
         OUTER APPLY (SELECT TOP 1 s.Name
                      FROM Service s WITH (NOLOCK)
                               JOIN CommunityGroupService cgs WITH (NOLOCK) ON cgs.ServiceID = s.ID
                      WHERE cgs.CommunityGroupID = cg.ID
                        AND s.id = 11) AS CallCenterTexting
         OUTER APPLY (SELECT TOP 1 s.Name
                      FROM Service s WITH (NOLOCK)
                               JOIN CommunityGroupService cgs WITH (NOLOCK) ON cgs.ServiceID = s.ID
                      WHERE cgs.CommunityGroupID = cg.ID
                        AND s.id = 8) AS CallCenterEmails
         OUTER APPLY (SELECT TOP 1 s.Name
                      FROM Service s WITH (NOLOCK)
                               JOIN CommunityGroupService cgs WITH (NOLOCK) ON cgs.ServiceID = s.ID
                      WHERE cgs.CommunityGroupID = cg.ID
                        AND s.id = 6) AS CallCenterFollowUp
         OUTER APPLY (SELECT top 1 max(con1.contactDate) 'MostRecentContact',
                                   cap1.IsActive
                      FROM Community comm1
                               JOIN Client cl1 WITH (nolock) ON cl1.id = c.ClientID
                               JOIN CommunityCommunityGroup ccg1 WITH (NOLOCK) ON ccg1.CommunityID = comm1.id
                               JOIN Contact con1 WITH (nolock) ON con1.CommunityID = c.ID
                               LEFT JOIN webpages_UsersInRoles wuir1 WITH (nolock) ON wuir1.UserId = con1.AgentID
                               JOIN CommunityApplication cap1 WITH (nolock) ON cap1.CommunityID = comm1.ID
                      WHERE con1.ContactDate >= GETDATE() - 30
                        AND con1.AgentID != -1
                        AND con1.AgentID != -2
                        AND wuir1.RoleId != 1
                        AND wuir1.RoleId != 5
                        AND wuir1.RoleId != 9
                        AND ccg1.communitygroupID = cg.id
                      GROUP BY cap1.IsActive) CC
GROUP BY cl.ID, cl.OrganizationName, c.ID, c.CommunityName, pms.Name, c.CreatedOn,  ct.ID, RI.ID,
ComType.type_checkerr,
         CallCenterCalls.Name,
         CallCenterFollowUp.Name,
         CallCenterEmails.Name,
         CallCenterTexting.Name,
         CC.isActive,
         CC.MostRecentContact,
         UnitCount,
         a.AddressLine1,
         a.City,
         s.Name,
         a.Zip,
         RPA.FirstName, RPA.LastName,
         LMA.FirstName, LMA.LastName,
         RI.ID,
         crp.experian_active, crp.transunion_active, crp.equifax_active;