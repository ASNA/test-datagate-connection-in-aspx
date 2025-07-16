
<%@ Page Language="AVR" %><%@ Import Namespace="System.Net.Sockets" %>
<%@ Import Namespace="System.Net.NetworkInformation" %>
<%@ Import Namespace="System.Collections.Generic" %>

<%@ Import Namespace="ASNA.DataGate.Client" %>
<%@ Import Namespace="ASNA.DataGate.Common" %>
<%@ Import Namespace="ASNA.DataGate.DataLink" %>
<%@ Import Namespace="ASNA.DataGate.Providers" %>



<script runat="server">
    DclFld DgDb       Type(AdgConnection)
    DclFld DgProfile  Type(SourceProfile)
    DclFld DgFile     Type(FileAdapter)   
    DclFld DgDataSet  Type(AdgDataSet)    

    DclFld Library Type(*String)
    DclFld File Type(*String) 
    DclFld FieldName Type(*String) 
    DclFld FieldValue Type(*String) 

    DclFld StatusMessage Type(*String) Inz('')
    DclFld ErrorMessage Type(*String) Inz('') 
    DclFld InnerMessage Type(*String) Inz('') 

    BegSr Page_Load Access(*Private) Event(*This.Load)
        DclSrParm sender Type(*Object)
        DclSrParm e Type(System.EventArgs)

        DclFld FormInputs Type(Dictionary(*of *String, *String)) New()

        FormInputs.Add('platform', GetFormInput('platform')) 
        FormInputs.Add('user', GetFormInput('user')) 
        FormInputs.Add('password', GetFormInput('password')) 
        FormInputs.Add('server', GetFormInput('server')) 
        FormInputs.Add('dblabel', GetFormInput('dblabel'))
        FormInputs.Add('port', GetFormInput('port')) 
        FormInputs.Add('library', GetFormInput('library')) 
        FormInputs.Add('file', GetFormInput('file')) 
        FormInputs.Add('fieldname', GetFormInput('fieldname')) 

        StatusMessage = ''
        ErrorMessage = ''
        InnerMessage = ''
        FieldValue = ''
        FieldName = ''

        If ( FormInputs['port'] <> *Blanks) 
            Try 
                TestConnection(FormInputs) 
                If (AttemptRecordRead()) 
                    StatusMessage = String.Format('Success connecting. Field ''{0}'' value is: ''{1}''', FieldName, FieldValue) 
                Else 
                    StatusMessage = String.Format('Success connecting. No read attempt made (are all read inputs provided?)')  
                EndIf 
            Catch ex Type(Exception) 
                ErrorMessage = ex.Message
                If (ErrorMessage.Contains('DataGate Service did not respond'))
                    ErrorMessage = String.Format('{0}<div>Its likely that DG isn''t present on {1}, isn''t started on {1}, or there is trouble with port {2}.</div>', ErrorMessage, FormInputs['server'], FormInputs['port'])                        
                EndIf 
                If ex.InnerException <> *Nothing 
                    InnerMessage = ex.InnerException.Message + 'Roger'
                    InnerMessage = String.Format('{0}<div>{1}</div><div>{2}</div>',InnerMessage, PingServer(FormInputs), CheckPort(FormInputs))
                EndIf 
            EndTry 
        EndIf 
    EndSr 

    BegSr TestConnection 
        DclSrParm FormInputs  Type(Dictionary(*of *String, *String))

        DgProfile = *New SourceProfile()

        SetLocalConnectionProperties(FormInputs) 
    
        Library = FormInputs['library']
        File = FormInputs['file']
        Fieldname = FormInputs['fieldname']

        DgDb = *New AdgConnection(DgProfile) 
        DgFile = *New FileAdapter(DgDb, LibraryFile(Library,File))
        DgFile.AccessMode = AccessMode.Read

        DgDb.Open()

        If (AttemptRecordRead()) 
            Try 
                DgFile.OpenNewAdgDataSet( *ByRef DgDataSet )  
            Catch ex Type(Exception)
                Throw *New Exception(String.Format('Error opening {0}/{1} file', Library, file))                        
            EndTry
            DgFile.ReadSequential( DgDataSet, ReadSequentialMode.Next, LockRequest.Read )
            FieldValue = GetDataGateFieldValue(Fieldname)
            DgFile.Close()
        EndIf

        DgDb.Close()             
    EndSr

    BegSr SetLocalConnectionProperties
        DclSrParm FormInputs  Type(Dictionary(*of *String, *String))

        DclFld Platform Type(*String) Inz('*DATALINK') 

        If (FormInputs['platform'] = 'DSS') 
            Platform = '*SQLOLEDB'
        EndIf

        If (FormInputs['platform'] = 'LOCAL')
            DgProfile.User = '*Domain'
            DgProfile.Label = FormInputs['dblabel']
            DgProfile.Server = '*LOCAL'
            DgProfile.PlatformAttribute = Platform
            DgProfile.Port = FormInputs['port']
        Else 
            DgProfile.User = FormInputs['user']
            DgProfile.Password = FormInputs['password']
            DgProfile.Server = FormInputs['server']
            DgProfile.Label = DgProfile.Server 
            DgProfile.PlatformAttribute = Platform 
            DgProfile.Port = FormInputs['port']
        EndIf 
    EndSr

    BegFunc AttemptRecordRead Type(*Boolean)
        LeaveSr Library <> *Blanks AND File <> *BLANKS AND FieldName <> *Blanks 
    EndFunc

    BegFunc GetFormInput Type(*String) 
        DclSrParm FormFieldName Type(*String) 

        DclFld Result Type(*String) Inz('')

        If Request[FormFieldName] AND NOT String.IsNullOrEmpty(Request[FormFieldName].ToString()) 
            Result = Request[FormFieldName].ToString() 
        EndIf 

        Session[FormFieldName] = Result 

        LeaveSr Result
    EndFunc

    BegFunc LibraryFile  Type( *String ) 
        DclSrParm Library  Type( *String ) 
        DclSrParm File     Type( *String )
        
        LeaveSr String.Format( "{0}/{1}", Library.Trim(), File.Trim() )
    EndFunc 

    BegFunc GetDataGateFieldValue Type(*String)
        DclSrParm FieldName Type(*String) 
        Try 
            LeaveSr DgDataSet.Tables[0].Rows[0][DgDataSet.Tables[0].Columns[FieldName]].ToString()  
        Catch ex Type(Exception) 
            Throw *New Exception(String.Format('Field name not found: {0}', FieldName))        
        EndTry 
    EndFunc

    BegFunc GetSavedFormInput Type(*String) 
        DclSrParm FieldName Type(*String) 

        If (Session[FieldName] <> *Nothing) 
            LeaveSr Session[FieldName].ToString()
        Else
            LeaveSr ''
        EndIf 

    EndFunc 

    BegFunc PingServer Type(*String) 
        DclSrParm FormInputs  Type(Dictionary(*of *String, *String))

        DclFld Server Type(*String)
        DclFld MyPing Type(Ping) New()
        DclFld Reply Type(PingReply)              

        DclFld Result Type(*String)
        
        Server = FormInputs['server']

        Try 
            Reply = myPing.Send(Server, 1000)
        
            If Reply.Status = IPStatus.Success
                Result = String.Format('<br>Ping to {0} succeeded.', Server)
            Else 
                Result = String.Format('<br>Ping to {0} failed', Server)
            EndIf 
        Catch ex Type(Exception) 
            Result = String.Format('Attempt to ping server {0}failed.', Server)
        EndTry 

        LeaveSr Result 
    EndFunc


    BegFunc CheckPort  Type(*String) 
        DclSrParm FormInputs  Type(Dictionary(*of *String, *String))

        DclFld Port Type(*Integer4) 
        DclFld Server Type(*String)

        DclFld Result Type(*String)

        Server = FormInputs['server']
        Port = FormInputs['port']

        BegUsing tcpc Type(TcpClient) Value(*New TcpClient()) 
            Try 
                tcpc.Connect(Server, Port)      
                Result = String.Format('Port {0} appears to be open', Port)
            Catch ex Type(Exception) 
                Result = String.Format('<br>Port {0} does not appear to be open to {1}.', Port, Server) 
            EndTry 
        EndUsing 

        LeaveSr Result
    EndFunc


</script>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
    <title>ASNA DataGate Connection Tester</title>
    <link rel="stylesheet" href="https://matcha.mizu.sh/matcha.css" />
    <style>
        body {
            font-size: 80%;
        }

        label {
            margin: 0 0 0 0;
        }

        form div.form-group {
            margin-bottom: .8rem;
        }

        button {
            margin-block-start: 1rem;            
        }

        .message {
            margin-left: 1rem;
            margin-bottom: 1rem;
        }

        .success:empty {
            display: none;
        } 

        .error {
            color: red;
        }
        .error:empty {
            display: none;
        } 

        .hide {
            display: none;
        }
        .optional-values {
            margin-top: 2rem;
            margin-bottom: .5rem;
        }

        #copied-message {
            /* Initially hidden */
            display: none;
            opacity: 0;

            /* Style the message */
            color: #28a745; /* A nice green color */
            font-weight: bold;
            margin-left: 15px; /* Add some space next to the button */

            /* Define the fade animation */
            transition: opacity 0.5s ease-in-out; /* Fade will take 0.5 seconds */
        }

    </style>
</head>
<body>
    <div class="form-container">
        <h2>ASNA DataGate Connection Tester</h2>

        <div class="message success">
            <%= StatusMessage %>
        </div>

        <div class="message error">
            <div>
            <%= ErrorMessage %>
            </div>
            <div>
            <%= InnerMessage %>
            </div>
        </div>


        <form id="form1" runat="server">
            <!-- User Input -->
                <div class="form-group">
                    <label for="platformType">Platform</label>
                    <select id="platform" name="platform" value="<%= GetSavedFormInput('platform') %>">
                        <option value="IBMI">DataGate for IBM i</option>
                        <option value="DSS">DataGate for SQL Server</option>
                        <option value="LOCAL">DataGate for Windows/Servers</option>
                    </select>
                </div>

                <div class="form-group user-input">
                    <label for="user">User</label>
                    <input
                        type="text"
                        id="user"
                        name="user"
                        placeholder="Enter username - omit for local DB"
                        value="<%= GetSavedFormInput('user') %>"
                    />
                </div>

                <!-- Password Input -->
                <div class="form-group password-input">
                    <label for="password">Password</label>
                    <input
                        type="text"
                        id="password"
                        name="password"
                        placeholder="Enter password - omit for local DB"
                        value="<%= GetSavedFormInput('password') %>"
                    />
                </div>

                <!-- Server Input -->
                <div class="form-group server-input">
                    <label for="server">Server</label>
                    <input
                        type="text"
                        id="server"
                        name="server"
                        placeholder="e.g., 192.168.1.1 or *Local"
                        required
                        title="Please enter a valid IPv4 address."
                        value="<%= GetSavedFormInput('server') %>"
                    />
                </div>

                <!-- DB Label Input -->
                <div class="form-group dblabel-input">
                    <label for="dblabel">DB Label</label>
                    <input
                        type="text"
                        id="dblabel"
                        name="dblabel"
                        placeholder="Database label--provide for local DB only"
                        title="Database label--provide for local DB only"
                        value="<%= GetSavedFormInput('dblabel') %>"
                    />
                </div>

                <!-- Port Input -->
                <div class="form-group">
                    <label for="port">Port</label>
                    <input
                        type="text"
                        id="port"
                        name="port"
                        placeholder="DataGate TCP/IP Port (default = 5042)"
                        required
                        value="<%= GetSavedFormInput('port') %>"
                    />
                </div>

                <div class="optional-values">These values are optional. They test reading a file. All three must be provided to do the read test.</div>

                <!-- Library Input -->
                <div class="form-group">
                    <label for="library">Library</label>
                    <input
                        type="text"
                        id="library"
                        name="library"
                        placeholder="Library name to prove read"
                        value="<%= GetSavedFormInput('library') %>"
                    />
                </div>

                <!-- File Input -->
                <div class="form-group">
                    <label for="file">File</label>
                    <input
                        type="text"
                        id="file"
                        name="file"
                        placeholder="File name to prove read"
                        value="<%= GetSavedFormInput('file') %>"
                    />
                </div>

                <!-- Field name Input -->
                <div class="form-group">
                    <label for="fieldname">Field name</label>
                    <input
                        type="text"
                        id="fieldname"
                        name="fieldname"
                        placeholder="Field name to prove read"
                        value="<%= GetSavedFormInput('fieldname') %>"
                    />
                </div>

            <!-- Submit Button -->
            <button type="submit" class="submit-btn">Connect</button>
            &nbsp;&nbsp;&nbsp;
            <a href="">Help using this utilty</a>
        </form>
    </div>


    <script>
        function selectOptionFromAttribute() {
            // 1. Get the <select> element by its ID
            const selectElement = document.getElementById('platform');

            // 2. Read the value from the 'value' HTML attribute
            const valueToSelect = selectElement.getAttribute('value');

            // 3. If the attribute exists, set the element's selected value
            if (valueToSelect) {
                selectElement.value = valueToSelect;
            }
        }

        function hideElement(inputName) {
            const targetElement = document.querySelector(`div.${inputName}-input`)

            if (!targetElement.classList.contains('hide')) {
                targetElement.classList.add('hide');
            }
        }

        function showElement(inputName) {
            const targetElement = document.querySelector(`div.${inputName}-input`)

            if (targetElement.classList.contains('hide')) {
                targetElement.classList.remove('hide');
            }
        }

        function setElementsDisplayForPlatform(platform) {

            switch (platform) {
                case "LOCAL":
                    hideElement('user')
                    hideElement('password')
                    hideElement('server')
                    showElement('dblabel')
                    //document.getElementById("user").value = ''
                    //document.getElementById("password").value = ''
                    //document.getElementById("server").value = ''
                    //document.getElementById("port").value = '5042'
                    break;
                case "IBMI":
                    showElement('user')
                    showElement('password')
                    showElement('server')
                    hideElement('dblabel')
                    break;
                case "DSS":
                    showElement('user')
                    showElement('password')
                    hideElement('server')
                    hideElement('dblabel')
                    break;
            }           
        }


        document.addEventListener('change', (event) => {
            setElementsDisplayForPlatform(event.target.value)
        });


        // Run the function after the document has loaded
        // to ensure the <select> element exists.
        document.addEventListener('DOMContentLoaded', (event) => {
            const selectElement = document.getElementById('platform');
            selectOptionFromAttribute();

            setElementsDisplayForPlatform(selectElement.value)

            const x = 'x'
        });


    </script>

</body>
</html>
