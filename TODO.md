### To do:
* Update simulation using a "background job" (removed background processing when upgrading to Vapor 4)

### Done:
* Supporting players should be able to build components
* Rewrite DB operations to use Result type instead of throw errors from Futures
* There are now three different starting techs: focus on tech, cash or a mix of both.
* new tech trees that have focus in tech, space production or money generation
* tech requirements for components
* Gameplay: Players can activate effects from improvements by spending action points to make the game more interactive.
* Authentication:
    * Login using e-mailaddress and password
    * Create user with password
    * Form validation (i.e. password requirements)
    * Change password, delete account