*** Settings ***
Library 	SeleniumLibrary
Library		FakerLibrary
Library 	OperatingSystem


# --listener /tmp/rfswarmagent/scripts/TestRepeater.py
Metadata    File 	TestRepeater.py

Suite Setup 	Suite Init
Suite Teardown 	Close All Browsers

*** Variables ***
# https://demo.opencart.com/
${StoreHost} 	192.168.13.66
${StorePage} 	https://${StoreHost}
${AdminPage} 	${StorePage}/admin

# ${ThinkTime}	30
${ThinkTime}	15
# ${ThinkTime}	5

${RFS_ROBOT}	1
${WaitTimout}		120
${RFS_ROBOT}	1


*** Test Cases ***
Opencart Sales
	Open Store
	Sleep    ${ThinkTime}
	${productPage}= 	Set Variable    False
	${items}= 	Evaluate 	random.randint(1, 5)
	FOR 	${i} 	IN RANGE 	${items}
		WHILE    not ${productPage}
			Open Random Page
			${previous kw}= 	Register Keyword To Run On Failure 	NONE
			# ${productPage}= 	Run Keyword And Return Status 	Page Should Contain 	//button[@id='button-cart']
			${productPage}= 	Run Keyword And Return Status 	Page Should Contain Element 	//button[@id='button-cart']
			Register Keyword To Run On Failure 	${previous kw}
			Sleep    ${ThinkTime}
		END
		Add To Cart
		${productPage}= 	Set Variable    False
	END
	Open Cart
	Sleep    ${ThinkTime}
	Checkout Step 1
	Sleep    ${ThinkTime}
	Checkout Step 2
	Sleep    ${ThinkTime}
	Checkout Step 3
	Sleep    ${ThinkTime}
	# Checkout Step 4
	# Sleep    ${ThinkTime}
	Checkout Step 5
	Sleep    ${ThinkTime}
	Checkout Step 6
	Sleep    ${ThinkTime}
	Confirm Order
	Sleep    ${ThinkTime}
	# Capture Page Screenshot

Process Orders
	Open Admin Page
	Sleep    ${ThinkTime}
	Admin Login 	OP001 	User123
	Sleep    ${ThinkTime}
	${process}= 	Evaluate 	random.randint(1, 10)
	FOR 	${i} 	IN RANGE 	${process}
		Open Orders
		Sleep    ${ThinkTime}
		${count}= 	Filter Orders    Pending
		Sleep    ${ThinkTime}
		IF	${count} > 0
			Open Order
			Sleep    ${ThinkTime}
			Update Order    Processing    Your Order is being Processed
			Sleep    ${ThinkTime}
		END
	END
	${process}= 	Evaluate 	random.randint(1, 10)
	FOR 	${i} 	IN RANGE 	${process}
		Open Orders
		Sleep    ${ThinkTime}
		${count}= 	Filter Orders    Processing
		Sleep    ${ThinkTime}
		IF	${count} > 0
			Open Order
			Sleep    ${ThinkTime}
			${TrackingNo}= 	Upc A
			Update Order    Shipped    Your Tracking Number is: ${TrackingNo}
			Sleep    ${ThinkTime}
		END
	END
	[Teardown]    Admin Logout

Replenish Stock
	Open Admin Page
	Sleep    ${ThinkTime}
	Admin Login 	WO001 	User123
	Sleep    ${ThinkTime}
	Open Products
	Sleep    ${ThinkTime}
	# Sort highest to lowest
	Click Link    Quantity
	# Sort lowest to highest
	Click Link    Quantity
	${Quantity}= 	Get Text    (//tr/td[6]/span)[1]
	IF 	${Quantity} < 150
		Open Product
		Sleep    ${ThinkTime}
		Update Product
		Sleep    ${ThinkTime}
	END
	# Capture Page Screenshot
	[Teardown]    Admin Logout


*** Keywords ***
Suite Init
	Clear Old Screenshots
	Open Blank Browser

Clear Old Screenshots
	Remove Files    ${CURDIR}/selenium*.png

Open Blank Browser
	[Documentation]		Open  Blank Browser
	Open Browser    about:blank    Chrome 		options=add_argument("--disable-popup-blocking"); add_argument("--ignore-certificate-errors")
	Set Window Size 	1200 	1350

Open Admin Page
	[Documentation]		Open Admin Page
	# Open Browser    ${StorePage}    Chrome 		options=add_argument("--disable-popup-blocking"); add_argument("--ignore-certificate-errors")
	${orig wait} = 	Set Selenium Implicit Wait 	1 seconds
	Go To    ${AdminPage}
	Wait Until Page Contains    Forgotten Password 	${WaitTimout}

Admin Login
	[Documentation]		Admin Login
	[Arguments] 			${User}			${Pass}
	Input Text 	id:input-username 	${User}
	Input Text 	id:input-password 	${Pass}
	Click Button    //button[contains(text(),'Login')]
	Wait Until Page Contains    Dashboard 	${WaitTimout}

Admin Logout
	[Documentation]		Admin Logout
	Click Link    //a[span[text()='Logout']]
	Wait Until Page Contains    Forgotten Password 	${WaitTimout}

Open Orders
	[Documentation]		Open Orders
	Click Link 	Dashboard
	# Sleep    0.1
	Click Link 	Sales
	# Sleep    0.1
	Wait Until Element Is Visible 	(//a[text()='Orders'])[1]
	Wait Until Element Is Enabled 	(//a[text()='Orders'])[1]
	Click Link 	Orders
	Wait Until Page Contains    Order List 	${WaitTimout}

Open Products
	[Documentation]		Open Products
	Click Link 	Dashboard
	# Sleep    0.1
	Click Link 	Catalog
	# Sleep    0.1
	Wait Until Element Is Visible 	(//a[text()='Products'])[1] 	${WaitTimout}
	Wait Until Element Is Enabled 	(//a[text()='Products'])[1] 	${WaitTimout}
	Click Link 	Products
	Wait Until Page Contains    Product List 	${WaitTimout}

Open Product
	[Documentation]		Open Product
	Click Link    (//tr/td//a[@data-original-title='Edit'])[1]
	Wait Until Page Contains    Meta Tag Title 	${WaitTimout}

Update Product
	[Documentation]		Update Product
	Click Link 	Data
	Scroll Element Into View 	id:input-quantity
	${Quantity}= 	Get Value    id:input-quantity
	${NewQuantity}= 	Evaluate    ${Quantity} + 50
	Input Text 	id:input-quantity 	${NewQuantity}
	Scroll Element Into View 	//button[@data-original-title='Save']
	Click Button    //button[@data-original-title='Save']
	# Success: You have modified products!
	Wait Until Page Contains    Success: You have modified products 	${WaitTimout}

Filter Orders
	[Documentation]		Filter Orders
	[Arguments] 			${Status}
	Select From List By Label 	id:input-order-status		${Status}
	Click Button    id:button-filter
	# Wait Until Page Contains Element    //td[text()='${Status}']
	Wait Until Page Contains    Showing 	${WaitTimout}
	${count}= 	Get Element Count 	//td[text()='${Status}']
	Click Link    Order ID
	[Return] 	${count}

Open Order
	[Documentation]		Open Order
	${count}= 	Get Element Count 	//tr/td//div/a
	IF 	${count} > ${RFS_ROBOT}
		Click Link    (//tr/td//div/a)[${RFS_ROBOT}]
	ELSE
		Click Link    (//tr/td//div/a)[1]
	END
	Wait Until Page Contains    Add Order History 	${WaitTimout}

Update Order
	[Documentation]		Update Order
	[Arguments] 			${Status} 		${Comment}
	Scroll Element Into View 	//button[contains(text(),'Add History')]

	Select From List By Label 	id:input-order-status 	${Status}
	Click Element    id:input-notify
	Input Text 	id:input-comment 	${Comment}
	# Press Keys 	id:input-comment 	${Comment}
	# Success: You have modified orders!
	# Capture Page Screenshot
	Click Button    //button[contains(text(),'Add History')]
	Wait Until Page Contains    Success: You have modified orders 	${WaitTimout}

Open Store
	[Documentation]		Open Store
	# Open Browser    ${StorePage}    Chrome 		options=add_argument("--disable-popup-blocking"); add_argument("--ignore-certificate-errors")
	${orig wait} = 	Set Selenium Implicit Wait 	1 seconds
	Go To    ${StorePage}
	Wait Until Page Contains    Your Store 	${WaitTimout}

Open Random Page
	[Documentation]		Open Random Page
	# ${xpath}= 	Set Variable     //a[contains(@href, '${StorePage}')]
	# ${xpath}= 	Set Variable     //a[contains(@href, '${StorePage}') and not(contains(@href, 'route'))]
	# ${xpath}= 	Set Variable     //a[contains(@href, '${StoreHost}') and not(contains(@href, 'route'))]
	${xpath}= 	Set Variable     //a[contains(@href, '${StoreHost}') and not(contains(@href, 'route')) and not(contains(@href, 'image'))]
	${count}= 	Get Element Count 	${xpath}
	${random}= 	Evaluate 	random.randint(1, ${count})
	# Scroll Element Into View 	(//a)[${random}]
	# Click Link    (//a)[${random}]
	${text}= 	Get Text 	(${xpath})[${random}]
	${href}= 	Get Element Attribute 	(${xpath})[${random}] 	href

	Log    [${random}] ${text} --> ${href} 	console=True
	# (//a[contains(@href, 'http://192.168.13.66')])[5]
	Go To    ${href}
	Wait Until Page Contains    Your Store 	${WaitTimout}


Add To Cart
	[Documentation]		Add Item To Cart
	${qty}= 	Evaluate 	random.randint(1, 3)
	Scroll Element Into View 	//button[@id='button-cart']
	Input Text 	//input[@id="input-quantity"] 	${qty}
	Sleep    0.1
	Click Button    //button[@id='button-cart']
	Wait Until Page Contains    Success: You have added 	${WaitTimout}

Open Cart
	[Documentation]		Open Cart
	Click Link    //a[@title="Shopping Cart"]
	Wait Until Page Contains    Shopping Cart 	${WaitTimout}


Checkout Step 1
	[Documentation]		Checkout - Checkout Options (Step 1)
	Click Link    //a[text()="Checkout"]
	Wait Until Page Contains    Returning Customer 	${WaitTimout}

Checkout Step 2
	[Documentation]		Checkout - Billing Details (Step 2)
	Click Element 	//label[input[@value='guest']]
	Click Button 		(//input[@value='Continue'])[1]
	Wait Until Page Contains    Your Personal Details 	${WaitTimout}

Checkout Step 3
	[Documentation]		Checkout - Delivery Details (Step 3)
	${fname}= 	First Name
	Input Text 	id:input-payment-firstname 	${fname}
	${lname}= 	Last Name
	Input Text 	id:input-payment-lastname 	${lname}
	${email}= 	Email
	Input Text 	id:input-payment-email 	${email}
	${phone}= 	Phone Number
	Input Text 	id:input-payment-telephone 	${phone}
	${addr}= 	Street Address
	Input Text 	id:input-payment-address-1 	${addr}
	${city}= 	City
	Input Text 	id:input-payment-city 	${city}
	${postcode}= 	Postcode
	Input Text 	id:input-payment-postcode 	${postcode}

	Scroll Element Into View 	(//input[@value='Continue'])[2]
	# input-payment-country
	# ${values} = 	Get List Items 	id:input-payment-country 	values=True
	# ${length} = 	Get Length 	${values}
	# ${random}= 	Evaluate 	random.randint(1, ${length-1})
	# Select From List By Value 	id:input-payment-country 	${values}[${random}]
	Select From List By Label 	id:input-payment-country 	United States

	Sleep    0.1
	# input-payment-zone
	# ${values} = 	Get List Items 	id:input-payment-zone 	values=True
	# ${length} = 	Get Length 	${values}
	# ${random}= 	Evaluate 	random.randint(1, ${length-1})
	${random}= 	Evaluate 	random.randint(1, 65)

	# Select From List By Value 	id:input-payment-zone 	${values}[${random}]
	Select From List By Index 	id:input-payment-zone 	${random}

	Click Button 		(//input[@value='Continue'])[2]
	# Wait Until Page Contains    preferred shipping method 	${WaitTimout}
	Wait Until Page Contains    Add Comments About Your Order 	${WaitTimout}

# Checkout Step 4
# 	[Documentation]		Checkout - Delivery Method (Step 4)
# 	Click Button 		(//input[@value='Continue'])[3]
# 	Wait Until Page Contains    preferred payment method  	${WaitTimout}

Checkout Step 5
	[Documentation]		Checkout - Payment Method (Step 5)
	Click Button 		(//input[@value='Continue'])[4]
	Wait Until Page Contains    preferred payment method 	${WaitTimout}


Checkout Step 6
	[Documentation]		Checkout - Confirm Order (Step 6)
	Click Element 	name:agree
	# Click Element 	//input[@name='agree']
	Click Button 		(//input[@value='Continue'])[5]

	Wait Until Page Contains    Unit Price 	${WaitTimout}


Confirm Order
	[Documentation]		Confirm Order
	Click Button 		//input[@value='Confirm Order']
	Wait Until Page Contains    order has been placed 	${WaitTimout}
