*** Settings ***
Documentation    Criação de PDFs dos chamados de suspensão
Resource         ChamadoSuspensao.resource
Suite Setup      Connect To Database    
...    ${DB_MODULE}    ${DB_PROD}    ${DB_USERNAME}    ${DB_PASSWORD}    ${DB_HOST}    autocommit=${True}
Suite Teardown    Run Keywords
...               Disconnect From Database    AND
...               Enviar E-mail Resumo

*** Variables ***
${DB_MODULE}      cx_Oracle
${DB_PROD}        GGASP
${DB_TEST}        GGAST2
${DB_USERNAME}    ROBO
${DB_PASSWORD}    Coper_automa
${DB_ADMIN_USERNAME}    GGAS_ADMIN
${DB_ADMIN_PASSWORD}    GGAS_ADMIN
${DB_HOST}        192.168.0.20

*** Tasks ***
Gerar Arquivos PDFs
    Gerar PDFs
    Atualizar Banco