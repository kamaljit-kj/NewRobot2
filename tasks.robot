*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.Desktop
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.Excel.Files

*** Tasks ***
Orders robots from RobotSpareBin Industries Inc
    Open the robot order website
    Log out and close the Browser
    [Teardown]    Log out and close the Browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://RobotSpareBinindustries.com/#/robot-order
    Close the annoying modal
    Download    https://RobotSpareBinindustries.com/orders.csv    overwrite=${True}
    ${order}=    Get Orders
Close the annoying modal
    Click Button    OK

Get Orders
    ${read_orders}=    Read table from CSV    orders.csv
    FOR    ${order}    IN    @{read_orders}
        Log    ${order}
        Wait Until Keyword Succeeds    10x    0.5 sec    Fill the form    ${order}
    END
    Create ZIP package from PDF files
    RETURN    ${read_orders}

Fill the form
    [Arguments]    ${order}
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath=//input[@placeholder='Enter the part number for the legs']    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    Preview
    Wait Until Keyword Succeeds    3x    0.5 sec    Click Button    Order

    ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
    ${screenshot}=    Set Variable    ${OUTPUT_DIR}${/}${order}[Order number].png
    Screenshot    id:robot-preview-image    ${screenshot}
    Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
    Wait Until Keyword Succeeds    10x    0.5 sec    Click Button    xpath=//button[@id='order-another']
    Close the annoying modal

Store the receipt as a PDF file
    [Arguments]    ${order}
    Wait Until Element Is Visible    id:receipt
    ${pdf}=    Get Element Attribute    id:receipt    outerHTML
    Html to Pdf    ${pdf}    ${OUTPUT_DIR}${/}${order}.pdf
    ${pdfname}=    Set Variable    ${OUTPUT_DIR}${/}${order}.pdf
    RETURN    ${pdfname}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screnshot}    ${pdf}
    ${list}=    Create List    ${screnshot}
    Open Pdf    ${pdf}
    Add Files To Pdf    ${list}    ${pdf}    append=${True}
    Close Pdf    ${pdf}
    # Wait until page 

Log out and close the Browser
    Close Browser

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}
    ...    ${zip_file_name}
