import UIKit
import WebKit
import Firebase

class Authentication: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!{
        didSet {
            webView.navigationDelegate = self
        }
    }
    
    @IBAction func unwindAndClearCoockies(segue: UIStoryboardSegue) {
        let coockieStore = webView.configuration.websiteDataStore.httpCookieStore
        coockieStore.getAllCookies {
            coocies in
            for coocke in coocies {
                coockieStore.delete(coocke)
            }
        }
        webView.load(buildAuthRequest())
    }
    
    func messageError() {
        let alert = UIAlertController(title: "Ошибка", message: "Введены неверные данные!!!", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    private func buildAuthRequest() -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "oauth.vk.com"
        components.path = "/authorize"
        components.queryItems = [
            URLQueryItem(name: "client_id", value: "7763626"),
            URLQueryItem(name: "scope", value: "262150"),
            URLQueryItem(name: "display", value: "mobile"),
            URLQueryItem(name: "redirect_uri", value: "https://oauth.vk.com/blank.html"),
            URLQueryItem(name: "response_type", value: "token"),
            URLQueryItem(name: "v", value: "5.130")
        ]
        
        return URLRequest(url: components.url!)
    }
    
    override func viewDidLoad() {
        RealmBase.inctance.startRealmBase()
        webView.load(buildAuthRequest())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension Authentication: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard let url = navigationResponse.response.url,
              url.path == "/blank.html",
              let fragment = url.fragment else {
            decisionHandler(.allow)
            return
        }
        
        let params = fragment
            .components(separatedBy: "&")
            .map { $0.components(separatedBy: "=") }
            .reduce([String: String]()) { result, param in
                var dict = result
                let key = param[0]
                let value = param[1]
                dict[key] = value
                
                return dict
            }
        
        guard let token = params["access_token"],
              let userIdString = params["user_id"],
              let _ = Int(userIdString)
        else {
            decisionHandler(.allow)
            return
        }
        
        Session.inctance.token = token
        Session.inctance.userId = Int(userIdString)!
        
        var networkManager = NetworkManager(token: Session.inctance.token)
        let ref = Database.database().reference(withPath: "userAuth")
        let userAuthRef = ref.child(userIdString)
        networkManager.loadUserById(idUser: userIdString, completion: { [weak self] result in
            switch result {
            case let .failure(error):
                print(error)
            case let .success(user):
                let zipcode = Int.random(in: 000001...999999)
                let user = user.first
                let currentUser = User(lastName: user?.lastName ?? "", firstName: user?.firstName ?? "", zipcode: zipcode)
                userAuthRef.setValue(currentUser.toAnyObject())
            }
        })
        
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "home")
        self.navigationController?.pushViewController(viewController, animated: true)
        self.present(viewController, animated: true)
        
        decisionHandler(.cancel)
        
    }
}

