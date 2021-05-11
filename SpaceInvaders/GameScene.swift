//
//  GameScene.swift
//  SpaceInvaders
//
//  Created by Guillermo Fernandez on 24/03/2021.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {

    var spaceShip: SKSpriteNode!
    var enemiesContainer: SKNode!
    private let laserShootSound = SKAction.playSoundFileNamed("lasershoot.wav", waitForCompletion: false)
    let bombSound = SKAction.playSoundFileNamed("bomb.wav", waitForCompletion: false)
    let boomSound = SKAction.playSoundFileNamed("boom.wav", waitForCompletion: false)
    private var spaceshipTouch: UITouch?
    var scoreLabel: SKLabelNode!
    var bombTimer: Timer?

    var currentScore: Int = 0
    let enemiesVerticaSpacing: CGFloat = 50.0
    var houseImpacts = [0, 0, 0, 0]

    var enemiesDirection: CGFloat = 1
    var enemiesSpeed: CGFloat = 1

    override func didMove(to view: SKView) {
        let spaceshipYPositon = -(self.size.height / 2) + 100

        self.backgroundColor = .black
        self.spaceShip = SKSpriteNode(imageNamed: "SpaceShip")
        self.spaceShip.name = "spaceship"
        self.spaceShip.size = CGSize(width: 50, height: 25)
        self.spaceShip.position = CGPoint(x: 0, y: spaceshipYPositon)
        self.addChild(self.spaceShip)
        self.spaceShip.physicsBody = SKPhysicsBody(texture: self.spaceShip.texture!, size: self.spaceShip.size)
        self.spaceShip.physicsBody?.categoryBitMask = 0x00001000
        self.spaceShip.physicsBody?.contactTestBitMask = 0x00000000
        self.spaceShip.physicsBody?.affectedByGravity = false
        self.spaceShip.physicsBody?.isDynamic = false

        self.addHouses(spaceshipYPositon)
        self.enemiesContainer = SKNode()
        self.enemiesContainer.position = CGPoint(x: 0, y: 0)
        self.addChild(self.enemiesContainer)
        self.addEnemies(at: 100)

        self.physicsWorld.contactDelegate = self

        self.scoreLabel = SKLabelNode(text: "SCORE: 0")
        self.scoreLabel.position = CGPoint(x: 0, y: (self.size.height / 2) - 50)
        self.addChild(self.scoreLabel)

        self.bombTimer = Timer.scheduledTimer(timeInterval: 1.5, target: self,
                                              selector: #selector(dropBomb), userInfo: nil, repeats: true)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard self.spaceshipTouch == nil else {
            self.createShoot()
            run(self.laserShootSound)
            return
        }

        if let touch = touches.first {
            self.spaceshipTouch = touch
            let newPosition = touch.location(in: self)
            let action = SKAction.moveTo(x: newPosition.x, duration: 0.5)
            action.timingMode = .easeInEaseOut
            self.spaceShip.run(action)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if touch == self.spaceshipTouch {
                let newPosition = touch.location(in: self)
                let action = SKAction.moveTo(x: newPosition.x, duration: 0.05)
                action.timingMode = .easeInEaseOut
                self.spaceShip.run(action)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if touch == self.spaceshipTouch {
                self.spaceshipTouch = nil
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if touch == self.spaceshipTouch {
                self.spaceshipTouch = nil
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        self.cleanPastShoots()

        let enemies = self.enemiesContainer.children
        for enemy in enemies {
            enemy.position = CGPoint(x: enemy.position.x + self.enemiesDirection * self.enemiesSpeed,
                                     y: enemy.position.y)
        }
        let enemySpacing = self.size.width / 16
        let startX = -(self.size.width / 2) + 30
        let maximumEnemyRightPosition: CGFloat = startX + ( 1.5 * CGFloat(9) * enemySpacing ) + 50
        let maximumEnemyLeftPosition: CGFloat = startX + ( 1.5 * CGFloat(0) * enemySpacing )

        for enemy in enemies {
            if self.enemiesDirection > 0.5 {
                print(enemy.position.x)
                if enemy.position.x >= maximumEnemyRightPosition {
                    self.enemiesDirection = -1

                }
            } else {
                if enemy.position.x <= maximumEnemyLeftPosition {
                    self.enemiesDirection = 1
                }
            }
        }

    }
}

extension GameScene {
    private func cleanPastShoots() {
        for node in children {
            guard node.name == "shoot" || node.name == "bomb" else { continue }
            if node.position.y > 700 || node.position.y < -700 {
                node.removeFromParent()
            }
        }
    }

    @objc
    private func dropBomb() {
        let bottomEnemies = self.enemiesContainer.children.filter { node in
            guard let isEnemy = node.name?.hasPrefix("Enemy"), isEnemy == true else { return false }
            let bottomPosition = CGPoint(x: node.position.x, y: node.position.y - self.enemiesVerticaSpacing)
            let enemies = self.enemiesContainer.nodes(at: bottomPosition)

            return !enemies.reduce(false) { $0 || $1.name!.hasPrefix("Enemy") }
        }

        guard bottomEnemies.count > 0 else { return }

        let shooterEnemyIndex = Int.random(in: 0..<bottomEnemies.count)
        let shooterEnemy = bottomEnemies[shooterEnemyIndex]
        let bombPosition = CGPoint(x: shooterEnemy.position.x,
                                   y: shooterEnemy.position.y - self.enemiesVerticaSpacing / 2)
        self.createBomb(at: bombPosition)
    }
}
