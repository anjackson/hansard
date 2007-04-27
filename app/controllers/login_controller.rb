class LoginController < ApplicationController
  before_filter :authorize, :except => [:login, :logout]

  def login
    if request.get?
      session[:username] = nil
    else
      # Split username on domain and alias
      split_username = params[:user][:name].split('\\', 2)
      if split_username.length != 2
        flash[:notice] = "You did not enter a properly formatted domain and alias" 
        redirect_to :action => 'login'
      else
        # Authenticate username and password
        domain = split_username[0]
        username = split_username[1]
        password = params[:user][:password]
        if authenticate domain, username, password
          # User has been authenticated
          session[:username] = username
          if @session["return_to"]
            redirect_to_path(@session["return_to"])
            @session["return_to"] = nil
          else
            redirect_to :controller => "sitting" 
          end
        else
          flash[:notice] = "Incorrect username or password" 
          redirect_to :action => 'login'
        end
      end
    end
  end

  def logout
    session[:username] = nil
  end
  require 'dl/win32'
  LOGON32_LOGON_NETWORK = 3
  LOGON32_PROVIDER_DEFAULT = 0
  BOOL_SUCCESS = 1
  AdvApi32 = DL.dlopen("advapi32")
  Kernel32 = DL.dlopen("kernel32")

  def authenticate(domain, username, password)
    # Load the DLL functions
    logon_user = AdvApi32['LogonUser', 'ISSSIIp']
    close_handle = Kernel32['CloseHandle', 'IL']

    # Normalize username and domain
    username = username.strip.downcase
    domain = domain.strip.downcase

    # Authenticate user
    ptoken = "\0" * 4
    r,rs = logon_user.call(username, domain, password, LOGON32_LOGON_NETWORK, LOGON32_PROVIDER_DEFAULT, ptoken)
    success = (r == BOOL_SUCCESS)

    # Close impersonation token
    token = ptoken.unpack('L')[0]
    close_handle.call(token)

    session[:username] = username
    return success
  end
end
