Pong was the first widely successful arcade game. It was released in 1972, and started the first arcade boom. The game may seem simple today, but it was designed directly in hardware. Essentially, Pong was a specialized computer designed to bounce a ball between two paddles and keep score.

### Goals:
- [x] Create an arena with two walls and a divider.
- [x] Add a paddle on either end of the play field. Use player inputs to move the paddles up and down.
- [x] Add a ball that moves around the playfield and bounces off of the paddles and walls.  
- [x] Detect when the ball leaves the playfield. Assign a point to the player who scored.
- [x] Track and display the score for each player.

### Stretch goals:
- [ ] Write an AI script that can follow the ball so you can play with only one player.
Hint: Following the ball with a paddle is easy, but it makes the opponent impossible to beat. You might want to make the AI less than perfect somehow.
- [ ] Add a menu and allow the player to reset the game.
- [ ] Add some basic sounds. Play a sound every time the ball collides with something, and every time a player scores.

### Custom goals:
- [ ] Implement more acurate bounce math
- [ ] Move to checking if there will be collision on the next frame

### Notes:
Need to modify the game loop to:
- First update and then draw
- Predict the collision the frame before to prevent penetration?

From reddit:
(0) user controls etc...
(1) ball is moving
(2) collision detection starts + ball intersects somewhere
(3) position of ball is reset back to the intersection point
(4) render

What the fuck I call things:
- Acceleration is constant
- There is no velocity?
- Speed is movement along a path
- Difference in position is called dp
