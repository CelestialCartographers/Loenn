local heart = {}

heart.name = "blackGem"
heart.depth = -2000000
heart.texture = "collectables/heartGem/0/00"
heart.placements = {
    name = "crystal_heart",
    data = {
        fake = false,
        removeCameraTriggers = false,
        fakeHeartDialog = "CH9_FAKE_HEART",
        keepGoingDialog = "CH9_KEEP_GOING"
    }
}

return heart