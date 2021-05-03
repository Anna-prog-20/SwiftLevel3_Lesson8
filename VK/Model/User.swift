import Foundation
import RealmSwift
import Firebase

@objcMembers
class User: RealmSwift.Object, Decodable {
    dynamic var id: Int = 0
    dynamic var firstName: String = ""
    dynamic var lastName: String = ""
    //var symbolName: String = ""
    dynamic var photo100: String = ""
    var zipcode: Int = 0
    var ref: DatabaseReference?
    var dateAuth: String = ""

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case photo100 = "photo_100"
    }
    
    override init() {
    }
    
    init(lastName: String, firstName: String, zipcode: Int) {
        self.lastName = lastName
        self.firstName = firstName
        self.zipcode = zipcode
        let formatter = DateFormatter()
        formatter.dateFormat = "HH: mm dd-MM-yyyy"
        self.dateAuth = formatter.string(from: Date())
    }
    
    init?(snapshot: DataSnapshot) {
        guard let value = snapshot.value as? [String: Any],
            let lastName = value["lastName"] as? String,
            let firstName = value["firstName"] as? String,
            let dateAuth = value["dateAuth"] as? String,
            let zipcode = value["zipcode"] as? Int else { return nil }

        self.lastName = lastName
        self.firstName = firstName
        self.dateAuth = dateAuth
        self.zipcode = zipcode

        self.ref = snapshot.ref
    }
    
    required convenience init(from decoder: Decoder) {
        self.init()
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {return}
        self.id = try! container.decode(Int.self, forKey: .id)
        self.firstName = try! container.decode(String.self, forKey: .firstName)
        self.lastName = try! container.decode(String.self, forKey: .lastName)
        //self.symbolName = self.lastName.first?.uppercased() ?? ""
        self.photo100 = try! container.decode(String.self, forKey: .photo100)
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    override class func ignoredProperties() -> [String] {
        return ["zipcode", "ref", "dateAuth"]
    }
    
    func toAnyObject() -> [String: Any] {
        [
            "lastName": lastName,
            "firstName": firstName,
            "dateAuth": dateAuth,
            "zipcode": zipcode
        ]
    }
}
