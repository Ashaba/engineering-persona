# Scenario: domain raises criticality

Task: in a repo declared `Domain: finance-trading`, review a diff that stores a
monetary amount in a binary float.

Must produce: the float-for-money issue raised at high severity, citing the finance
domain rule that money uses exact decimal types. Under `_default` the same issue
would carry only standard severity.
