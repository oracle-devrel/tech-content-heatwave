# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License (UPL), Version 1.0.

import oci
import os
import base64
from utils.exceptions import AskMEException, BackendConnectionException , UnknownException
from constants import CLIENT_TIMEOUT, FREEFORM_TAG_KEY, FREEFORM_TAG_VALUE, ADDITIONAL_FIELDS_LIST
from utils.util import setup_logging
logger = setup_logging()

COMPARTMENT_ID = os.environ['OCI_COMPARTMENT_ID']

REGION_ID = os.environ['OCI_REGION']
RETRY_STRATEGY = oci.retry.NoneRetryStrategy()

SECRET_MYSQL_USERNAME = "mysql_username"
SECRET_MYSQL_PASSWORD = "mysql_password"
SECRET_MYSQL_HOST_IP = "mysql_host_ip"

def get_signer_instance_principals():
    try:
        # get signer from instance principals token
        signer = oci.auth.signers.InstancePrincipalsSecurityTokenSigner()
    except Exception:
        logger.exception("There was an error while trying to get the oci signer")
        raise BackendConnectionException("There was an error while trying to get the oci signer")
    return signer

def get_os_client():
    signer = get_signer_instance_principals()
    try:
        client = oci.object_storage.ObjectStorageClient(config={}, signer=signer, retry_strategy=RETRY_STRATEGY, timeout=CLIENT_TIMEOUT)
    except Exception:
        logger.exception("There was an error while trying to get the object storage client")
        raise BackendConnectionException("There was an error while trying to get the object storage client")
    return client

def get_vault_client():
    signer = get_signer_instance_principals()
    try:
        client = oci.key_management.KmsVaultClient(config={}, signer=signer, retry_strategy=RETRY_STRATEGY, timeout=CLIENT_TIMEOUT)
    except Exception:
        logger.exception("There was an error while trying to get the vault client")
        raise BackendConnectionException("There was an error while trying to get the vault client")
    return client

def get_secrets_client():
    signer = get_signer_instance_principals()
    try:
        client = oci.secrets.SecretsClient(config={}, signer=signer, retry_strategy=RETRY_STRATEGY, timeout=CLIENT_TIMEOUT)
    except Exception:
        logger.exception("There was an error while trying to get the secret client")
        raise BackendConnectionException("There was an error while trying to get the secret client")
    return client

def get_namespace():
    try:
        os_client = get_os_client()
        namespace = os_client.get_namespace().data
    except Exception:
        logger.exception("There was an error while trying to fetch the namespace")
        raise BackendConnectionException ("There was an error while trying to fetch the namespace")
    return namespace

def get_askme_bucket_name(compartment_id=COMPARTMENT_ID):
    os_client = get_os_client()
    namespace_name = get_namespace()
    oci_response = oci.pagination.list_call_get_all_results(os_client.list_buckets,
                                                            namespace_name=namespace_name,
                                                            compartment_id=compartment_id,
                                                            fields=ADDITIONAL_FIELDS_LIST)
    if oci_response.status != 200:
        logger.error(f"Can't list the compartment buckets. status: {oci_response.status}")
        raise BackendConnectionException(f"Can't list the compartment buckets.")

    all_buckets = oci_response.data
    relevant_buckets = [bucket for bucket in all_buckets if bucket.freeform_tags.get(FREEFORM_TAG_KEY) == FREEFORM_TAG_VALUE]
    if len(relevant_buckets) != 1:
        logger.error(f"Can't find relevant bucket in the compartment {compartment_id}")
        raise  BackendConnectionException(f"Can't find relevant bucket in the compartment {compartment_id}")
    return relevant_buckets[0].name

def get_vault_id(compartment_id=COMPARTMENT_ID):
    vault_client = get_vault_client()
    oci_response = oci.pagination.list_call_get_all_results(vault_client.list_vaults,
                                                            compartment_id=compartment_id)
    if oci_response.status != 200:
        logger.error(f"Can't list the compartment vaults. status: {oci_response.status}")
        raise BackendConnectionException(f"Can't list the compartment vaults.")

    all_vaults = oci_response.data
    relevant_vaults = [vault for vault in all_vaults if vault.freeform_tags.get(FREEFORM_TAG_KEY) == FREEFORM_TAG_VALUE]
    if len(relevant_vaults) != 1:
        logger.error( f"Can't find relevant vault in the compartment {compartment_id}")
        raise BackendConnectionException( f"Can't find relevant vault in the compartment {compartment_id}")
    return relevant_vaults[0].id

def get_secret_value(vault_id, secret_name):
    secrets_client = get_secrets_client()
    oci_response = secrets_client.get_secret_bundle_by_name(secret_name, vault_id)
    if oci_response.status != 200:
        logger.error(f"Can't fetch the secret bundle by name. status: {oci_response.status}")
        raise BackendConnectionException(f"Can't fetch the secret bundle by name.")

    if oci_response.data.secret_bundle_content.content_type != "BASE64":
        logger.error("Secret not using base64 format")
        raise BackendConnectionException("Secret not using base64 format")
    return base64.b64decode(oci_response.data.secret_bundle_content.content).decode('UTF-8')

def upload_object_store_object(filepath, bucket_name, prefix):
    os_client = get_os_client()
    namespace_name = get_namespace()
    if not os.path.exists(filepath):
        logger.error("File does not exist!")
        raise AskMEException("File does not exist!")

    remote_filepath = os.path.join(prefix, os.path.basename(filepath))
    logger.info(f"Uploading {filepath} to object store ({remote_filepath})")
    with open(filepath, "rb") as f:
        put_object_response = os_client.put_object(namespace_name=namespace_name,
                                                   bucket_name=bucket_name,
                                                   object_name=remote_filepath,
                                                   put_object_body=f)
        if put_object_response.status not in [200, 204]:
            logger.error(f"Uploading the files to the object store failed. status: {put_object_response.status}")
            raise BackendConnectionException("Uploading the files to the object store failed.")
    logger.info("Uploading the files to the object store was successful")

def upload_object_store_bytes(data_bytes, filename, bucket_name, prefix):
    os_client = get_os_client()
    namespace_name = get_namespace()
    remote_filepath = os.path.join(prefix, filename)
    logger.info(f"Uploading data to object store ({remote_filepath})")
    put_object_response = os_client.put_object(namespace_name=namespace_name,
                                                   bucket_name=bucket_name,
                                                   object_name=remote_filepath,
                                                   put_object_body=data_bytes)
    if put_object_response.status not in [200, 204]:
        logger.error(f"Uploading the data to the object store failed. status: {put_object_response.status}")
        raise BackendConnectionException("Uploading the data to the object store failed.")
    logger.info("Uploading the data to the object store was successful")

def delete_object_store_folder(bucket_name, prefix):
    os_client = get_os_client()
    namespace_name = get_namespace()
    oci_response = oci.pagination.list_call_get_all_results(os_client.list_objects,
                                                            namespace_name=namespace_name,
                                                            bucket_name=bucket_name,
                                                            prefix=prefix)
    if oci_response.status != 200:
        logger.error(f"Can't list the object store objects from {bucket_name}:{prefix}. status: {oci_response.status}")
        raise BackendConnectionException(f"Can't list the object store objects.")
    all_os_objects = [os_object for os_object in oci_response.data.objects]
    logger.info(f"Removing {len(all_os_objects)} object(s) from '{prefix}'")
    for os_object in all_os_objects:
        delete_object_response = os_client.delete_object(namespace_name=namespace_name,
                                                    bucket_name=bucket_name,
                                                    object_name=os_object.name)
        if delete_object_response.status not in [200, 204]:
            logger.error(f"Deleting the object store object {os_object.name} failed. status: {delete_object_response.status}")
            raise BackendConnectionException("Deleting the object store object failed.")
        logger.info(f"Deleting the object store object {os_object.name} was successful")

def get_db_credentials():
    vault_id = get_vault_id()
    mysql_username = get_secret_value(vault_id, SECRET_MYSQL_USERNAME)
    mysql_password = get_secret_value(vault_id, SECRET_MYSQL_PASSWORD)
    mysql_host_ip = get_secret_value(vault_id, SECRET_MYSQL_HOST_IP)
    return mysql_host_ip, mysql_username, mysql_password