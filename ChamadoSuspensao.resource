*** Settings ***
Library    String
Library    DateTime
Library    Collections
Library    OperatingSystem
Library    RPA.PDF
Library    RPA.Database
Library    RPA.Email.ImapSmtp    smtp_server=mail.copergas.com.br

*** Variables ***
@{LISTA_CHAMADOS}
${QUANTIDADE_PDF}
${TD}    <td style="border: 1px solid black; padding: 8px; text-align: left;">

*** Keywords ***
Gerar PDFs
    ${TABLE}    Query
    ...    SELECT * FROM GGAS_ADMIN.VIEW_CHAMADO_SUSPENSAO_AUT WHERE DESCRICAO_CHAMADO LIKE 'Titulo%' ORDER BY DESCRICAO_PNT_CONS ASC
    ${QUANTIDADE_CHAMADOS}    Get Number Of Rows
    ...    GGAS_ADMIN.VIEW_CHAMADO_SUSPENSAO_AUT WHERE DESCRICAO_CHAMADO LIKE 'Titulo%'
    Set Global Variable    ${QUANTIDADE_CHAMADOS}

    ${dia_atual}    Get Current Date    result_format=%d/%m/%Y

    FOR    ${index}    ${chamado}    IN ENUMERATE    @{TABLE}
        ${chamado_data_abertura}    Convert Date    ${chamado}[DATA_ABERTURA]    result_format=%d/%m/%Y %H:%M
        ${dia_abertura}    Convert Date    ${chamado}[DATA_ABERTURA]    result_format=%d/%m/%Y

        # Separar o campo descrição em elementos
        ${descrição_chamado}    Convert To String   ${chamado}[DESCRICAO_CHAMADO]
        ${descrição_chamado}    Replace String    string=${descrição_chamado}    search_for=Titulo:${SPACE}    replace_with=${SPACE}
        ${descrição_chamado}    Replace String    string=${descrição_chamado}    search_for=Emissao:${SPACE}    replace_with=${SPACE}
        ${descrição_chamado}    Replace String    string=${descrição_chamado}    search_for=Vencimento:${SPACE}    replace_with=${SPACE}
        ${descrição_chamado}    Replace String    string=${descrição_chamado}    search_for=Valor:${SPACE}    replace_with=${SPACE}
        ${descrição_chamado}    Replace String    string=${descrição_chamado}    search_for=],${SPACE}    replace_with=]|   
        @{lista_descrição_chamado}    Split String   string=${descrição_chamado}    separator=|
        
        &{campos_PDF}    Create Dictionary    
        ...    NumeroProtocolo=${chamado}[NUMERO_PROTOCOLO]
        ...    NomeSolicitante=${chamado}[NOME_SOLICITANTE]
        ...    CnpjSolicitante=${chamado}[CPF_CNPJ]
        ...    TipoChamado=${chamado}[TIPO_CHAMADO]
        ...    AssuntoChamado=${chamado}[ASSUNTO_CHAMADO]
        ...    CanalAtendimento=${chamado}[CANAL_ATENDIMENTO]
        ...    UnidOrganizacional=${chamado}[UNIDADE_ORGANIZACIONAL]
        ...    Responsavel=${chamado}[RESPONSAVEL]
        ...    NomeCliente=${chamado}[NOME_SOLICITANTE]
        ...    NomeFantasia= 
        ...    NumeroContrato=${chamado}[NUMERO_CONTRATO]
        ...    MatriculaImovel=${chamado}[MATRICULA]
        ...    NomeFantasiaImovel=${chamado}[NOME_FANTASIA]
        ...    CepImovel=${chamado}[CEP]
        ...    EnderecoImovel=${chamado}[ENDERECO]
        ...    DescricaoImovel=${chamado}[DESCRICAO_PNT_CONS]
        ...    DataHoraRow1=${chamado_data_abertura}
        ...    UsuarioRow1=${chamado}[USUARIO]
        ...    ResponsavelRow1=${chamado}[RESPONSAVEL]
        ...    UnidOrganizacionalRow1=${chamado}[UNIDADE_ORGANIZACIONAL]
        ...    DescricaoTituloRow1=${lista_descrição_chamado}[0]
        ...    DescricaoEmissaoRow1=${lista_descrição_chamado}[1]
        ...    DescricaoVencimentoRow1=${lista_descrição_chamado}[2]
        ...    DescricaoValorRow1=${lista_descrição_chamado}[3]
        ...    OperacoesRow1=INCLUIDO
        ...    SituacaoRow1=${chamado}[STATUS_CHAMADO_ABERTO]
    
        ${folder_path}    Criar Pastas    ${chamado}[TIPO_CHAMADO]    ${chamado}[NOME_BAIRRO]

        IF    '${chamado}[TIPO_CHAMADO]' == 'GFIN - RES - SOLICITACOES'
            Set Local Variable    ${tipo_formulario}    .${/}Code${/}ChamadoSuspensao${/}Form_Residencial.pdf
        ELSE
            Set Local Variable    ${tipo_formulario}    .${/}Code${/}ChamadoSuspensao${/}Form_Comercial.pdf
        END

        Save Field Values    source_path=${tipo_formulario}    
        ...                  output_path=${folder_path}${/}${chamado}[NUMERO_PROTOCOLO] - ${chamado}[DESCRICAO_PNT_CONS] - Suspensão.pdf    
        ...                  newvals=${campos_PDF}

        ${QUANTIDADE_PDF}    Evaluate    ${QUANTIDADE_PDF} + 1

        Atualizar Lista E-mail
        ...    ${chamado}[NUMERO_PROTOCOLO]
        ...    ${chamado}[DESCRICAO_PNT_CONS]
        ...    ${chamado}[NOME_BAIRRO]
        ...    ${chamado}[TIPO_CHAMADO]
    
    END

    Set Global Variable    ${QUANTIDADE_PDF}


Criar Pastas
    [Arguments]    ${tipo}    ${bairro}

    IF    '${tipo}' == 'GFIN - RES - SOLICITACOES'
        Set Local Variable    ${folder_path}    .${/}Files${/}Chamados_Suspensao${/}Residencial${/}${bairro}
    ELSE
        Set Local Variable    ${folder_path}    .${/}Files${/}Chamados_Suspensao${/}Comercial${/}${bairro}
    END

    ${folder_exists}    Run Keyword And Return Status    Directory Should Exist    ${folder_path}
    IF    ${folder_exists} == $False
        Create Directory    ${folder_path}
    END

    [Return]    ${folder_path}


Atualizar Lista E-mail
    [Arguments]    ${numero_protocolo}    ${ponto_consumo}    ${bairro}    ${tipo}

    IF    '${tipo}' == 'GFIN - RES - SOLICITACOES'
        Set Local Variable    ${tipo_chamado_email}    RESIDENCIAL
    ELSE
        Set Local Variable    ${tipo_chamado_email}    COMERCIAL
    END

    Append To List    ${LISTA_CHAMADOS}
    ...    <tr>${td}${numero_protocolo}</td>${td}${ponto_consumo}</td>${td}${bairro}</td>${td}${tipo_chamado_email}</td></tr>


Enviar E-mail Resumo
    Authorize Smtp

    @{recipients}    Set Variable    victor.borella@copergas.com.br
    ...                              silas.souza@copergas.com.br
    ...                              jose.santos@copergas.com.br
    ...                              wellington.oliveira@copergas.com.br
    ...                              murilo.teixeira@copergas.com.br
      
    # ${recipient}    Set Variable    victor.borella@copergas.com.br

    ${subject}    Set Variable    Chamados de suspensão que foram criados PDFs

    ${base_message}    Get File    .${/}Code${/}ChamadoSuspensao${/}notificacaoSuspencao.html
    ${chamados_string}    Evaluate    ''.join(${LISTA_CHAMADOS})
    ${final_message}    Format String    ${base_message}    table=${chamados_string}

    ${tamanho}    Get Length    ${LISTA_CHAMADOS}

    IF    '${tamanho}' > '0'
        Send Message    sender=automacao.geti@copergas.com.br    
        ...             recipients=@{recipients}    
        ...             subject=${subject}    
        ...             body=${final_message}    
        ...             html=${True}
    END


Atualizar Banco
    ${is_empty}    Run Keyword And Return Status    Should Be Empty    ${QUANTIDADE_PDF}
    Pass Execution If    ${is_empty}    Nao existem PDFs para serem gerados

    IF    ${QUANTIDADE_CHAMADOS} == ${QUANTIDADE_PDF}
        Query    statement=UPDATE CHAMADO SET CHAM_DS = 'Arquivo PDF criado - '||CHAM_DS WHERE USSI_CD_RESPONSAVEL = 282 AND CHAM_DS LIKE 'Titulo%' AND (CHAS_CD = 301 OR CHAS_CD = 304) AND UNOR_CD = 37 AND ENCO_CD_STATUS = 423 AND CAAT_CD = 8
        # Log To Console    UPDATE
    END