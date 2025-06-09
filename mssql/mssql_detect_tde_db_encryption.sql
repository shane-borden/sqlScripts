SELECT
    d.name AS DatabaseName,
    d.is_encrypted,
    dek.encryption_state,
    CASE dek.encryption_state
        WHEN 0 THEN 'No Database Encryption Key Present, Not Encrypted'
        WHEN 1 THEN 'Unencrypted'
        WHEN 2 THEN 'Encryption in Progress'
        WHEN 3 THEN 'Encrypted'
        WHEN 4 THEN 'Key Change in Progress'
        WHEN 5 THEN 'Decryption in Progress'
        WHEN 6 THEN 'Protection Change in Progress'
        ELSE 'Not Encrypted or No Key' -- Or NULL if no entry in dek
    END AS EncryptionStatusDescription,
    dek.percent_complete,
    dek.key_algorithm,
    dek.key_length
FROM
    sys.databases d
LEFT JOIN
    sys.dm_database_encryption_keys dek ON d.database_id = dek.database_id
WHERE d.is_encrypted <> 0;