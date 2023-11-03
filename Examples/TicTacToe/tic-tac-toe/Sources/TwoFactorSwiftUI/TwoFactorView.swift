import AuthenticationClient
import ComposableArchitecture
import SwiftUI
import TwoFactorCore

public struct TwoFactorView: View {
  @State var store: StoreOf<TwoFactor>

  public init(store: StoreOf<TwoFactor>) {
    self.store = store
  }

  public var body: some View {
    Form {
      Text(#"To confirm the second factor enter "1234" into the form."#)

      Section {
        TextField("1234", text: self.$store.code)
          .keyboardType(.numberPad)
      }

      HStack {
        Button("Submit") {
          // NB: SwiftUI will print errors to the console about "AttributeGraph: cycle detected"
          //     if you disable a text field while it is focused. This hack will force all
          //     fields to unfocus before we send the action to the view store.
          // CF: https://stackoverflow.com/a/69653555
          UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
          )
          self.store.send(.view(.submitButtonTapped))
        }
        .disabled(self.store.isSubmitButtonDisabled)

        if self.store.isActivityIndicatorVisible {
          Spacer()
          ProgressView()
        }
      }
    }
    .alert(store: self.store.scope(state: \.$alert, action: \.alert))
    .disabled(self.store.isFormDisabled)
    .navigationTitle("Confirmation Code")
  }
}

fileprivate extension TwoFactor.State {
  var isActivityIndicatorVisible: Bool { self.isTwoFactorRequestInFlight }
  var isFormDisabled: Bool { self.isTwoFactorRequestInFlight }
  var isSubmitButtonDisabled: Bool { !self.isFormValid }
}

struct TwoFactorView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      TwoFactorView(
        store: Store(initialState: TwoFactor.State(token: "deadbeef")) {
          TwoFactor()
        } withDependencies: {
          $0.authenticationClient.login = { _ in
            AuthenticationResponse(token: "deadbeef", twoFactorRequired: false)
          }
          $0.authenticationClient.twoFactor = { _ in
            AuthenticationResponse(token: "deadbeef", twoFactorRequired: false)
          }
        }
      )
    }
  }
}
