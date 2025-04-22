# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License (UPL), Version 1.0.

class AskMEException(Exception):
    pass

class BackendConfigurationException(AskMEException):
    pass

class BackendConnectionException(AskMEException):
    pass

class BackendExecutionException(AskMEException):
    pass

class UnknownException(AskMEException):
    pass