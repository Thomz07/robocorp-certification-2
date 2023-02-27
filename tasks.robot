*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.
...

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.Tables
Library             RPA.HTTP
Library             RPA.FileSystem
Library             RPA.PDF
Library             RPA.Archive


*** Variables ***
${robot_receipt_html}


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download Excel file
    Get Orders
    Create ZIP with PDFs


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order    maximized=True

Download Excel file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Write Excel data in form
    [Arguments]    ${id}    ${head}    ${body}    ${legs}    ${address}
    Click Cookie Message
    Select From List By Value    head    ${head}
    Click Element    id-body-${body}
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${legs}
    Input Text    address    ${address}
    Click Element    preview
    Wait Until Element Is Visible    robot-preview-image
    Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}${id}.png
    Click Element    order
    ${error}=    Run Keyword And Return Status    Element Should Be Visible    class:alert-danger
    WHILE    ${error}
        Wait Until Element Is Visible    class:alert-danger
        Click Element    order
        ${error}=    Run Keyword And Return Status    Element Should Be Visible    class:alert-danger
    END
    Wait Until Element Is Visible    id:receipt
    Save Robot Receipt    ${id}
    Click Element    order-another

Save Excel data in variable
    [Arguments]    ${data}
    ${id}=    Set Variable    ${data}[Order number]
    ${head}=    Set Variable    ${data}[Head]
    ${body}=    Set Variable    ${data}[Body]
    ${legs}=    Set Variable    ${data}[Legs]
    ${address}=    Set Variable    ${data}[Address]
    Write Excel data in form    ${id}    ${head}    ${body}    ${legs}    ${address}

Get Orders
    ${csv_data}=    Read table from CSV    orders.csv    header=${True}
    FOR    ${data}    IN    @{csv_data}
        Save Excel data in variable    ${data}
    END

Click Cookie Message
    Wait Until Page Contains Element    class:modal-content
    Click Button    OK

Save Robot Receipt
    [Arguments]    ${robot_id}
    ${robot_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    ${robot_receipt_html}=    Catenate
    ...    ${robot_receipt_html}
    ...    <br><img src="${OUTPUT_DIR}${/}${robot_id}.png" width="200"/>
    Html To Pdf    ${robot_receipt_html}    ${OUTPUT_DIR}${/}Robot receipt PDF${/}${robot_id}.pdf
    Log    ${robot_receipt_html}

Create ZIP with PDFs
    Archive Folder With ZIP
    ...    ${OUTPUT_DIR}${/}Robot receipt PDF${/}
    ...    ${OUTPUT_DIR}${/}robots_receipts.zip
    Remove Directory    ${OUTPUT_DIR}${/}Robot receipt PDF${/}    recursive=${True}
