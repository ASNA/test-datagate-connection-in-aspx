# Testing DataGate connections with ASP.NET


Before you deploy a Visual RPG (AVR) ASP.NET Web application for production use, it’s a good idea to ensure the DataGate connection is working on the Web Server. You can do that with the [DataGate Monitor](/en/kb/datagate-monitor), but that doesn’t confirm that ASP.NET is working and that AVR is working with ASP.NET; nor does it test that the WebPak license is valid.



This article provides a single-file ASPX page that tests DataGate connections, as well as ASP.NET and AVR interoperability for Visual RPG ASP.NET Web applications and WebPak licensing.



Put the single `test-dg.aspx` file in your Website or virtual directory and direct your browser it. There are no other compilation or deployment steps—its code is compiled at runtime when the file is displayed in the browser.



`test-dg.aspx` does 100% of its work with a single file; there is no code behind. The file has AVR server side code, JavaScript client code, HTML, and the CSS. The file is compiled at runtime by ASP.NET. You can drop the file as-is into the root of an empty virtual directory or Web site root.



This test page works with DataGate for IBM i, DataGate for SQL Server, and DataGate for Windows and Servers (aka, the local ASNA database).



Testing connection attributes with this page can help ensure that the attributes you use with your DataGate Database Name will work with your deployed ASNA Visual RPG application.



Using this test file before you deploy your Visual RPG Web application:



*   Confirms ASP.NET is installed and worked

*   Confirms that AVR is installed working

*   Confirms that you can connect to your target server successfully

*   Using the read option, it confirms that the user specified has permission to the file read and it confirms that your WebPak license is valid.



The error messages provided help troubleshoot connection errors.



Figures 1 and 2 below show the test page in action.



![Success connecting with DataGate for IBM i](https://nyc3.digitaloceanspaces.com/asna-assets/assets/articles/test-dg-connection-success.png) 



Figure 1. Success connecting to DataGate for IBM i.



![Failure connecting with DataGate for IBM i](https://nyc3.digitaloceanspaces.com/asna-assets/assets/articles/test-dg-connection-error.png) 



Figure 2. Failure connecting to DataGate for IBM i.



## Optional test to read a record



When provided, the bottom three inputs (Library, File, Field name) attempt to read a record from the file info provided. This read test is necessary to test that the WebPak license is valid. The WebPak licensed isn’t checked at connection time, it’s checked when DataGate does some kind of file IO (eg, read, write, update, or delete). The read test also ensures the user profile used in the DataGate name has permissions to the file.



## Using the DataGate ASP.NET Connection Tester


Put the `test-dg.aspx` file in the root of where your project is hosted on IIS. Point your browser to that test page. For example, if the domain for your IIS instance is



`test.mycompany.com`



Then use



`test.mycompany.com/test-dg.aspx`



in your browser.



Generally, you should use the `test-dg.aspx` in the root of an IIS site or virtual directory before you first deploy your app. However, can also add `test-dg.aspx` to deployed sites as long as they were not deployed with the "Precompile during publishing" option (shown in Figure 3 below).



![Failure connecting with DataGate for IBM i](https://nyc3.digitaloceanspaces.com/asna-assets/assets/articles/test-dg-connection-precompiled.png) 



Figure 3. `test-dg.aspx` can't be added directly to projects deployed with the 'precompile during publishing' option.



For using the connection tester with precompiled projects, you need to either:



*   Add the `test-db.asp` file to the root your project and redeploy it

*   Temporarily remove the contents of the IIS site or virtual directory, test the connection, then restore the contents.



## Attribute-specific details



### DataGate for IBM i



*   User: IBM i user

*   Password: IBM i user password

*   Server: IBM i IP address or name

*   DB Label: Can be any text value or empty

*   Port: Default value is 5042. [How to confirm the IBM i's DataGate TCP/IP port assignment](https://www.asna.com/en/kb/confirm-datagate-port)



### DataGate for SQL Server



*   User: `*Domain` or SQL Server user

*   Password: Empty if `*Domain` or SQL Server user password

*   Server: SQL Server instance name

*   DB Label: Must be `SQL`

*   Port: Must be 5042



### DataGate for Windows and Servers



*   User: Must be `*Domain`

*   Password: Must be empty

*   Server: Must be `*Local`

*   DB Label: Must be the assigned Database Label (see the section below)

*   Port: Must be 5042





