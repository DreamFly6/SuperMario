//
//  GoldSprite.swift
//  SuperMario
//
//  Created by haharsw on 2019/6/11.
//  Copyright © 2019 haharsw. All rights reserved.
//

import SpriteKit

fileprivate enum GoldTileType: String {
    case gold = "goldm"
    case power = "mushroom"
    case lifeAdd = "mushroom_life"
    case void = "void"
}

class GoldSprite : SKSpriteNode {
    fileprivate let goldTileType: GoldTileType
    let type: FragileGridType
    var empty: Bool = false
    
    init(_ type: FragileGridType, _ tileName: String) {
        self.type = type
        self.goldTileType = GoldTileType(rawValue: tileName) ?? .gold
        
        let texFileName = "goldm" + type.rawValue + (self.goldTileType == .void ? "_4" :  "_1")
        let tex = SKTexture(imageNamed: texFileName)
        super.init(texture: tex, color: SKColor.clear, size: tex.size())
        
        if self.goldTileType == .lifeAdd || self.goldTileType == .void {
            self.alpha = 0.0
        }

        let physicalSize = CGSize(width: tex.size().width, height: tex.size().height - 0.1)
        let physicalCenter = CGPoint(x: 0.0, y: -0.1 / 2.0)
        physicsBody = SKPhysicsBody(rectangleOf: physicalSize, center: physicalCenter)
        physicsBody!.friction = 0.0
        physicsBody!.restitution = 0.0
        physicsBody!.categoryBitMask = PhysicsCategory.GoldMetal
        physicsBody!.collisionBitMask = physicsBody!.collisionBitMask & ~(PhysicsCategory.ErasablePlat | PhysicsCategory.EBarrier)
        physicsBody!.isDynamic = false
    
        if goldTileType != .void {
            run(animation, withKey: "animation")
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) hasn't been implemented.")
    }
    
    // MARK: Animation Stuff
    
    private static var sAnimation: SKAction!
    private static var sTexType = ""
    var animation: SKAction {
        get {
            if GoldSprite.sTexType != self.type.rawValue {
                GoldSprite.sAnimation = makeAnimation(texName: "goldm", suffix: self.type.rawValue, count: 3, timePerFrame: 0.5)
                GoldSprite.sTexType = self.type.rawValue
            }
            
            return GoldSprite.sAnimation
        }
    }
}

extension GoldSprite: MarioBumpFragileNode {
    
    func marioBump() {
        if self.empty == false {
            if self.goldTileType != .void {
                let texFileName = "goldm" + self.type.rawValue + "_4"
                self.texture = SKTexture(imageNamed: texFileName)
                self.removeAction(forKey: "animation")
                
                let pos = CGPoint(x: position.x, y: position.y + GameConstant.TileGridLength * 0.75)
                GameScene.addScore(score: ScoreConfig.hitOutBonus, pos: pos)
            }
            
            switch self.goldTileType {
            case .gold:
                spawnCoinFlyAnimation()
                GameHUD.instance.coinCount += 1
            case .power:
                spawnPowerUpSprite(false)
            case .lifeAdd:
                spawnPowerUpSprite(true)
            case .void:
                self.alpha = 1.0
                AudioManager.play(sound: .HitHard)
            }
            
            self.empty = true
        } else {
            AudioManager.play(sound: .HitHard)
        }
        
        checkContactPhysicsBody()
    }
    
    // MARK: Helper Method
    
    private func checkContactPhysicsBody() {
        let half_w = size.width * 0.49
        let half_h = size.height * 0.5
        let rect = CGRect(x: position.x - half_w, y: position.y + half_h, width: size.width * 0.98, height: 1.0)
        GameScene.checkRectForShake(rect: rect)
    }
    
    private func spawnCoinFlyAnimation() {
        let coinFileName = "flycoin" + self.type.rawValue + "_1"
        let coin = SKSpriteNode(imageNamed: coinFileName)
        coin.zPosition = 1.0
        coin.position = CGPoint(x: 0.0, y: GameConstant.TileGridLength * 0.75)
        coin.run(GameAnimations.instance.flyCoinAnimation)
        self.addChild(coin)
        
        AudioManager.play(sound: .Coin)
    }
    
    private func spawnPowerUpSprite(_ lifeMushroom: Bool) {
        if lifeMushroom == false && GameManager.instance.mario.marioPower != .A {
            let flower = FlowerSprite(self.type)
            let position = CGPoint(x: self.position.x, y: self.position.y + GameConstant.TileGridLength)
            flower.zPosition = self.zPosition
            flower.cropNode.position = position + self.parent!.position
            GameScene.addFlower(flower.cropNode)
        } else {
            let mushroom = MushroomSprite(self.type, lifeMushroom)
            let position = CGPoint(x: self.position.x, y: self.position.y + GameConstant.TileGridLength)
            mushroom.zPosition = self.zPosition
            mushroom.cropNode.position = position + self.parent!.position
            GameScene.addMushroom(mushroom.cropNode)
            
            if lifeMushroom == true {
                let fadeIn = SKAction.fadeIn(withDuration: 0.125)
                self.run(fadeIn)
            }
        }
        
        AudioManager.play(sound: .SpawnPowerup)
    }
}

extension GoldSprite: MarioShapeshifting {
    func marioWillShapeshift() {
        guard self.goldTileType != .void else { return }
        if empty == false {
            self.removeAction(forKey: "animation")
        }
    }
    
    func marioDidShapeshift() {
        guard self.goldTileType != .void else { return }
        if empty == false {
            self.run(animation, withKey: "animation")
        }
    }
}
