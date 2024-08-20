class_name Part
extends Node2D


const AUTO_CONNECT_DISTANCE_SQUARED_THRESHOLD := 3.0 * 3.0

const MAX_HEALTH_MODULATION_ALPHA := 1.0
const MIN_HEALTH_MODULATION_ALPHA := 0.5

const FIRE_EFFECT_ALPHA := 1.0
const FIRE_EFFECT_SCALE := 0.4

const HIGH_HEALTH_RATIO_THRESHOLD := 0.8
const MEDIUM_HEALTH_RATIO_THRESHOLD := 0.5
const LOW_HEALTH_RATIO_THRESHOLD := 0.2

@export var growth_level := 1
@export var growth_progress_value := 1

# The mass of this part, as a whole.
@export var mass: float = 0.5

@onready var space_explosion = $SpaceExplosion

var attached_to_player := false

var looks_for_nearby_connections_when_entering_tree := true
var initialized_connections := false

var fire_level := 0
var fire_effect: Node2D

var attach_points: Array[AttachPoint] = []

var parent_connection: PartConnection
var child_connections: Array[PartConnection] = []

var player_collision_shape_instance: CollisionShape2D

# Component constituents of this part. These are auto-registered.
var light_guns: Array[LightGun] = []
var heavy_guns: Array[HeavyGun] = []
var thrusters: Array[Thruster] = []

# Health is special, as there's only ever one
var health: HealthComponent = null
# TODO: Add thrusters, shields, heavy guns, etc


func _init() -> void:
    add_to_group(Config.PARTS_GROUP)


func _enter_tree() -> void:
    _init_shape()
    _init_parent()


func _ready() -> void:
    _init_components(self)
    if looks_for_nearby_connections_when_entering_tree:
        _init_connections()

    # TODO: Remove.
    #_on_health_changed($HealthComponent.max_health * 0.1, $HealthComponent.max_health)


func _init_shape() -> void:
    var hurtbox = get_node("Hurtbox")
    assert(hurtbox != null and hurtbox is Hurtbox)
    assert(hurtbox.get_children().size() == 1 and hurtbox.get_children()[0] is CollisionShape2D)


func _init_parent() -> void:
    var parent_node := get_parent()
    if parent_node is PartsDrop:
        parent_node.parts.push_back(self)
        attached_to_player = false
        parent_node.on_part_added(self)
        parent_node.growth_level = max(parent_node.growth_level, growth_level)
    elif parent_node is PlayerBody:
        parent_node.parts.push_back(self)
        attached_to_player = true
        parent_node.on_part_added(self)
    else:
        assert(false)


func _init_connections() -> void:
    initialized_connections = true

    var other_parts: Array[Part]
    var parent_node := get_parent()
    if parent_node is Drop:
        other_parts = parent_node.parts
    elif parent_node is PlayerBody:
        other_parts = parent_node.parts

    for other_part in other_parts:
        if other_part == self:
            # Don't connect to yourself.
            continue
        if !other_part.initialized_connections:
            # Let the the other part connect to this part.
            continue

        for other_attach_point in other_part.attach_points:
            if other_attach_point.connection != null:
                # This AttachPoint is already connected.
                continue
            for self_attach_point in attach_points:
                if self_attach_point.connection != null:
                    # This AttachPoint is already connected.
                    continue
                if self_attach_point.global_position.distance_squared_to(
                        other_attach_point.global_position) <= AUTO_CONNECT_DISTANCE_SQUARED_THRESHOLD:
                    other_attach_point.part.add_child_connection(other_attach_point, self_attach_point)
                    # Only attach yourself to a single parent.
                    return


func _init_components(node: Node) -> void:
    if node is HealthComponent:
        _init_health_component(node)
    elif node is LightGun:
        node.growth_level = growth_level
        light_guns.push_back(node)
    elif node is HeavyGun:
        node.growth_level = growth_level
        heavy_guns.push_back(node)
    elif node is Thruster:
        node.growth_level = growth_level
        thrusters.push_back(node)
    elif node is AttachPoint:
        attach_points.push_back(node)

    for child in node.get_children():
        _init_components(child)


func _init_health_component(h: HealthComponent) -> void:
    assert(health == null)
    health = h
    health.health_changed.connect(_on_health_changed)
    health.health_depleted.connect(_on_health_depleted)


func on_attached() -> void:
    # Assign the hurtbox to the right layer
    var hurtbox: Area2D = get_node("Hurtbox")
    if hurtbox:
        hurtbox.collision_layer = Config.PLAYER_COLLISION_LAYER

    for g in light_guns:
        g.projectile_collision_mask = Config.ENEMY_COLLISION_LAYER | Config.LEVEL_COLLISION_LAYER
    for g in heavy_guns:
        g.projectile_collision_mask = Config.ENEMY_COLLISION_LAYER | Config.LEVEL_COLLISION_LAYER


func on_detached() -> void:
    # Assign the hurtbox to the right layer
    var hurtbox: Area2D = get_node("Hurtbox")
    if hurtbox:
        hurtbox.collision_layer = 0

    for g in light_guns:
        g.projectile_collision_mask = Config.LEVEL_COLLISION_LAYER
    for g in heavy_guns:
        g.projectile_collision_mask = Config.LEVEL_COLLISION_LAYER


func _on_health_changed(new_health: float, prev_health: float) -> void:
    if self == Global.player.body.core_part:
        print(new_health)

    var weight: float = new_health / $HealthComponent.max_health

    #get_sprite().modulate.a = lerp(MIN_HEALTH_MODULATION_ALPHA, MAX_HEALTH_MODULATION_ALPHA, weight)

    var next_fire_level: int
    if weight <= LOW_HEALTH_RATIO_THRESHOLD:
        next_fire_level = 3
    elif weight <= MEDIUM_HEALTH_RATIO_THRESHOLD:
        next_fire_level = 2
    elif weight <= HIGH_HEALTH_RATIO_THRESHOLD:
        next_fire_level = 1
    else:
        next_fire_level = 0

    if fire_level != next_fire_level:
        fire_level = next_fire_level

        if is_instance_valid(fire_effect):
            fire_effect.queue_free()

        var fire_effect_scene: PackedScene
        match next_fire_level:
            1:
                fire_effect_scene = Config.PART_FIRE_LOW_EFFECT_SCENE
            2:
                fire_effect_scene = Config.PART_FIRE_MEDIUM_EFFECT_SCENE
            3:
                fire_effect_scene = Config.PART_FIRE_HIGH_EFFECT_SCENE
            _:
                assert(false)
                return

        fire_effect = fire_effect_scene.instantiate()
        fire_effect.modulate.a = FIRE_EFFECT_ALPHA
        fire_effect.scale = Vector2.ONE * FIRE_EFFECT_SCALE
        fire_effect.rotation = randi_range(0, 3) * PI / 2
        add_child(fire_effect)

        # Randomize the starting frame.
        var animated_sprite: AnimatedSprite2D = fire_effect.get_node("AnimatedSprite2D")
        var animation: StringName = animated_sprite.animation
        var frame_count := animated_sprite.sprite_frames.get_frame_count(animation)
        animated_sprite.frame = randi_range(0, frame_count - 1)


func _on_health_depleted() -> void:
    _on_health_depleted_deferred.call_deferred()


func _on_health_depleted_deferred() -> void:
    # Sfx.play(Sfx.SPACE_EXPLOSION)
    assert(is_instance_valid(space_explosion))
    space_explosion.reparent(Global.level)
    space_explosion.play()

    print('part destroyed!')
    if self == Global.player.body.core_part:
        # Destruction of core means death
        Global.player.die()
    else:
        Global.player.body.destroy_part(self)

    await space_explosion.finished
    space_explosion.queue_free()


func get_bounding_box() -> Rect2:
    var sprite_size := get_sprite_size()
    var sprite_position := get_sprite_position()
    var sprite_bounds := Rect2(sprite_position, sprite_size)

    var bounds := sprite_bounds

    for attach_point in attach_points:
        bounds.expand(attach_point.global_position)

    return bounds


func get_sprite() -> Node2D:
    if has_node("AnimatedSprite2D"):
        var sprite := get_node("AnimatedSprite2D")
        assert(sprite is AnimatedSprite2D)
        return sprite
    else:
        assert(has_node("Sprite2D"))
        var sprite := get_node("Sprite2D")
        assert(sprite is Sprite2D)
        return sprite


func get_sprite_size() -> Vector2:
    var texture: Texture2D
    var sprite := get_sprite()
    if sprite is AnimatedSprite2D:
        var animation: StringName = sprite.animation
        texture = sprite.sprite_frames.get_frame_texture(animation, 0)
    else:
        texture = sprite.texture
    return texture.get_size()


func get_sprite_position() -> Vector2:
    var sprite := get_sprite()
    return sprite.global_position


func get_healthbox_collision_shape() -> CollisionShape2D:
    return get_node("Hurtbox").get_children()[0]


func get_all_descendants(out_descendants: Array[Part]) -> void:
    for connection in child_connections:
        out_descendants.append(connection.child.part)
        connection.child.part.get_all_descendants(out_descendants)


func add_child_connection(parent_point: AttachPoint, child_point: AttachPoint) -> void:
    assert(!is_instance_valid(child_point.part.parent_connection))
    assert(attach_points.has(parent_point))
    for connection in child_connections:
        assert(connection.parent != parent_point)
        assert(connection.child != child_point)
    for connection in child_point.part.child_connections:
        assert(connection.parent != child_point)
        assert(connection.child != parent_point)

    var connection := PartConnection.new(parent_point, child_point)
    child_connections.push_back(connection)
    child_point.part.parent_connection = connection

    child_point.part.attached_to_player = parent_point.part.attached_to_player

    # Snap the new part to align attachment points.
    var translation := parent_point.global_position - child_point.global_position
    child_point.part.translate_part(translation)


func remove_child_connection(connection: PartConnection) -> void:
    assert(child_connections.has(connection))
    assert(connection.parent.part == self)

    child_connections.erase(connection)
    connection.parent.connection = null
    connection.child.connection = null
    connection.child.part.parent_connection = null
    connection.child.part.attached_to_player = false


func reassign_parent_connection(new_parent_connection: PartConnection) -> void:
    if parent_connection == new_parent_connection:
        # Already done.
        return

    var old_parent_connection := parent_connection
    var old_parent := old_parent_connection.parent if parent_connection != null else null
    var old_child := old_parent_connection.child if parent_connection != null else null

    parent_connection = new_parent_connection

    # Make sure this part no longer considers the new parent as a child.
    if new_parent_connection != null:
        var old_child_connection: PartConnection
        for connection in child_connections:
            if (connection.child.part == new_parent_connection.parent.part or
                    connection.parent.part == new_parent_connection.parent.part):
                old_child_connection = connection
                break
        if old_child_connection != null:
            child_connections.erase(old_child_connection)

    if old_parent_connection == null:
        # We don't need to recurse to re-assign the old parent's connection since
        # this part used to be the root.
        return

    child_connections.push_back(old_parent_connection)

    # Update the old parent to now consider this part as its parent.
    old_parent_connection.parent = old_child
    old_parent_connection.child = old_parent
    old_parent.part.reassign_parent_connection(old_parent_connection)


func translate_part(translation: Vector2) -> void:
    global_position += translation
    for connection in child_connections:
        connection.child.part.translate_part(translation)


func destroy() -> void:
    var part := self
    var parent_node: Node2D = get_parent()
    assert(parent_node is PlayerBody or parent_node is PartsDrop)
    var parts: Array[Part] = parent_node.parts

    assert(is_instance_valid(part))
    assert(parts.has(part))

    var descendant_parts: Array[Part] = []
    part.get_all_descendants(descendant_parts)

    # Remove any tracked AttachPoint overlaps.
    var overlaps_to_remove: Array[PotentialConnectionOverlap] = []
    for attach_point in Global.player.body.potential_connection_overlaps:
        var overlap: PotentialConnectionOverlap = \
            Global.player.body.potential_connection_overlaps[attach_point]
        if (attach_points.has(overlap.attached_point) or
                attach_points.has(overlap.detached_point)):
            overlaps_to_remove.push_back(overlap)
    for overlap in overlaps_to_remove:
        Global.player.body._remove_potential_overlap_mapping(overlap.attached_point)
        Global.player.body._remove_potential_overlap_mapping(overlap.detached_point)

    parts.erase(part)
    if part == Global.player.body.core_part:
        Global.player.body.core_part = null

    # Detach from children.
    var child_connections_copy := part.child_connections.duplicate()
    for connection in child_connections_copy:
        part.remove_child_connection(connection)

    # Detach from parent.
    if is_instance_valid(part.parent_connection):
        part.parent_connection.parent.part.remove_child_connection(part.parent_connection)

    var drop := Config.EMPTY_PARTS_DROP_SCENE.instantiate()
    Global.level.add_child(drop)
    Global.level.drops.push_back(drop)

    for descendant_part in descendant_parts:
        assert(is_instance_valid(descendant_part))
        assert(parts.has(descendant_part))
        parts.erase(descendant_part)
        descendant_part.looks_for_nearby_connections_when_entering_tree = false
        descendant_part.on_removed()
        descendant_part.reparent(drop)

    part.on_removed()
    part.queue_free()


func on_removed() -> void:
    if is_instance_valid(player_collision_shape_instance):
        player_collision_shape_instance.queue_free()
    player_collision_shape_instance = null