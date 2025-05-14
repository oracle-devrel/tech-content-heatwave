# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License (UPL), Version 1.0.

import oci
import os
import base64
from utils.exceptions import AskMEException, BackendConnectionException
from constants import CLIENT_TIMEOUT, ADDITIONAL_FIELDS_LIST
from utils.util import setup_logging
logger = setup_logging()

COMPARTMENT_ID = os.environ['OCI_COMPARTMENT_ID']

REGION_ID = os.environ['OCI_REGION']
RETRY_STRATEGY = oci.retry.NoneRetryStrategy()

BUCKET_NAME = os.environ['BUCKET_NAME']
VAULT_ID = os.environ['VAULT_ID']
IS_GENAI_REGION = os.environ['IS_GENAI_REGION'].lower() == 'true'

MYSQL_USERNAME_VAULT_SECRET_NAME = os.environ['MYSQL_USERNAME_VAULT_SECRET_NAME']
MYSQL_PASSWORD_VAULT_SECRET_NAME = os.environ['MYSQL_PASSWORD_VAULT_SECRET_NAME']
MYSQL_HOST_IP_VAULT_SECRET_NAME = os.environ['MYSQL_HOST_IP_VAULT_SECRET_NAME']

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

def get_secret_value(secret_name):
    secrets_client = get_secrets_client()
    oci_response = secrets_client.get_secret_bundle_by_name(secret_name, VAULT_ID)
    if oci_response.status != 200:
        logger.error(f"Can't fetch the secret bundle by name. status: {oci_response.status}")
        raise BackendConnectionException(f"Can't fetch the secret bundle by name.")

    if oci_response.data.secret_bundle_content.content_type != "BASE64":
        logger.error("Secret not using base64 format")
        raise BackendConnectionException("Secret not using base64 format")
    return base64.b64decode(oci_response.data.secret_bundle_content.content).decode('UTF-8')

def upload_object_store_object(filepath, prefix):
    os_client = get_os_client()
    namespace_name = get_namespace()
    if not os.path.exists(filepath):
        logger.error("File does not exist!")
        raise AskMEException("File does not exist!")

    remote_filepath = os.path.join(prefix, os.path.basename(filepath))
    logger.info(f"Uploading {filepath} to object store ({remote_filepath})")
    with open(filepath, "rb") as f:
        put_object_response = os_client.put_object(namespace_name=namespace_name,
                                                   bucket_name=BUCKET_NAME,
                                                   object_name=remote_filepath,
                                                   put_object_body=f)
        if put_object_response.status not in [200, 204]:
            logger.error(f"Uploading the files to the object store failed. status: {put_object_response.status}")
            raise BackendConnectionException("Uploading the files to the object store failed.")
    logger.info("Uploading the files to the object store was successful")

def upload_object_store_bytes(data_bytes, filename, prefix):
    os_client = get_os_client()
    namespace_name = get_namespace()
    remote_filepath = os.path.join(prefix, filename)
    logger.info(f"Uploading data to object store ({remote_filepath})")
    put_object_response = os_client.put_object(namespace_name=namespace_name,
                                               bucket_name=BUCKET_NAME,
                                               object_name=remote_filepath,
                                               put_object_body=data_bytes)
    if put_object_response.status not in [200, 204]:
        logger.error(f"Uploading the data to the object store failed. status: {put_object_response.status}")
        raise BackendConnectionException("Uploading the data to the object store failed.")
    logger.info("Uploading the data to the object store was successful")

def delete_object_store_folder(prefix):
    os_client = get_os_client()
    namespace_name = get_namespace()
    oci_response = oci.pagination.list_call_get_all_results(os_client.list_objects,
                                                            namespace_name=namespace_name,
                                                            bucket_name=BUCKET_NAME,
                                                            prefix=prefix)
    if oci_response.status != 200:
        logger.error(f"Can't list the object store objects from {BUCKET_NAME}:{prefix}. status: {oci_response.status}")
        raise BackendConnectionException(f"Can't list the object store objects.")
    all_os_objects = [os_object for os_object in oci_response.data.objects]
    logger.info(f"Removing {len(all_os_objects)} object(s) from '{prefix}'")
    for os_object in all_os_objects:
        delete_object_response = os_client.delete_object(namespace_name=namespace_name,
                                                         bucket_name=BUCKET_NAME,
                                                         object_name=os_object.name)
        if delete_object_response.status not in [200, 204]:
            logger.error(f"Deleting the object store object {os_object.name} failed. status: {delete_object_response.status}")
            raise BackendConnectionException("Deleting the object store object failed.")
        logger.info(f"Deleting the object store object {os_object.name} was successful")

def get_db_credentials():
    mysql_username = get_secret_value(MYSQL_USERNAME_VAULT_SECRET_NAME)
    mysql_password = get_secret_value(MYSQL_PASSWORD_VAULT_SECRET_NAME)
    mysql_host_ip = get_secret_value(MYSQL_HOST_IP_VAULT_SECRET_NAME)
    return mysql_host_ip, mysql_username, mysql_password