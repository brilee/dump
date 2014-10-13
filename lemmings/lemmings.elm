import Keyboard
import Window

-- MODEL
mario = { x=0, y=500, vx=0, vy=0, dir="right" }

platform = { xmin=-250, xmax=200, y = 250 }

near m platform = m.x < platform.xmax && m.x > platform.xmin

-- UPDATE -- ("m" is for Mario)
jump {y} m = if y > 0 && m.y == 0 then { m | vy <- 5 } else m
gravity t m = 
  if ((m.y <= platform.y && m.y - t*m.vy >= platform.y) && 
    near m platform)
    then {m | vy <- 0, y <- platform.y}
  else if m.y <= 0
    then {m | vy <- 0, y <- 0}
  else
    { m | vy <- m.vy - t/4 }
physics t m = { m | x <- m.x + t*m.vx , y <- max 0 (m.y + t*m.vy) }
walk {x} m = 
  if m.vx == 0 && (m.y == 0 || (m.y == platform.y && near m platform))
    then { m | vx <- 2}
  else if m.x > 300 && m.y == 0
    then { m | vx <- -2}
  else if m.x < -300 && m.y == 0
    then { m | vx <- 2}
  else
    m

step (dt, keys) =
  jump keys >> gravity dt >> walk keys >> physics dt


-- DISPLAY
render (w',h') mario =
  let (w,h) = (toFloat w', toFloat h')
      verb = if | mario.y  >  0 -> "jump"
                | mario.vx /= 0 -> "walk"
                | otherwise     -> "stand"
      src = "/imgs/mario/" ++ verb ++ "/" ++ mario.dir ++ ".gif"
  in collage w' h'
      [ rect w h  |> filled (rgb 174 238 238)
      , rect w 50 |> filled (rgb 74 163 41)
                  |> move (0, 24 - h/2)
      , toForm (image 35 35 src) |> move (mario.x, mario.y + 62 - h/2)
      ]

-- MARIO
input = let delta = lift (\t -> t/20) (fps 25)
        in  sampleOn delta (lift2 (,) delta Keyboard.arrows)

main = lift2 render Window.dimensions (foldp step mario input)