-- force_load.lua — bypass paste parser
-- built by odil9 — discord.gg/xGDFJ29MmA

print("[odil9] force loader mulai")

local ok, err = pcall(function()
    local encoded = "cHJpbnQoIltvZGlsOV0gbWVudSBtdW5jdWwhIikKbG9jYWwgcGxheWVycyA9IGdhbWU6R2V0U2VydmljZSgiUGxheWVycyIpCmxvY2FsIGxwID0gcGxheWVycy5Mb2NhbFBsYXllcgppZiBub3QgbHAgdGhlbiByZXR1cm4gZW5kCgppZiBnZXRnZW52KCkuX29kaWw5X21lbnUgYW5kIGdldGdlbnYoKS5fb2RpbDlfbWVudS5kZXN0cm95IHRoZW4gZ2V0Z2Vudi().X29kaWw5X21lbnUuZGVzdHJveSgpIGVuZAoKbG9jYWwgZ3VpID0gSW5zdGFuY2UubmV3KCJTY3JlZW5HdWkiKQpndWkuTmFtZSA9ICJvZGlsOV9mb3JjZWQiCmd1aS5SZXNldE9uU3Bhd24gPSBmYWxzZQpndWkuSWdub3JlR3VpSW5zZXQgPSB0cnVlCmd1aS5QYXJlbnQgPSBnZXRodWkoKSBvciBnYW1lOEdldFNlcnZpY2UoIkNvcmVHdWkiKQoKbG9jYWwgZnJhbWUgPSBJbnN0YW5jZS5uZXcoIkZyYW1lIikKZnJhbWUuU2l6ZSA9IFVEaW0yLm5ldygwLCA0MDAsIDAsIDMwMCkKZnJhbWUuUG9zaXRpb24gPSBVRGltMi5uZXcoMCwgMjAsIDAsIDIwKQpmcmFtZS5CYWNrZ3JvdW5kQ29sb3IzID0gQ29sb3IzLmZyb21SR0IoMTgsIDE2LCAyMikKZnJhbWUuQm9yZGVyU2l6ZVBpeGVsID0gMgpmcmFtZS5Cb3JkZXJDb2xvcjMgPSBDb2xvcjMuZnJvbVJHQigyNTUsIDYwLCAxODApCmZyYW1lLkFjdGl2ZSA9IHRydWUKZnJhbWUuRHJhZ2dhYmxlID0gdHJ1ZQpmcmFtZS5QYXJlbnQgPSBndWkKCmxvY2FsIHRpdGxlID0gSW5zdGFuY2UubmV3KCJUZXh0TGFiZWwiKQp0aXRsZS5TaXplID0gVURpbTIubmV3KDEsIC0yMCwgMCwgMzApCnRpdGxlLlBvc2l0aW9uID0gVURpbTIubmV3KDAsIDEwLCAwLCAxMCkKdGl0bGUuQmFja2dyb3VuZFRyYW5zcGFyZW5jeSA9IDEKdGl0bGUuVGV4dCA9ICJvZGlsOSBmb3JjZWQgbWVudSAiCnRpdGxlLlRleHRDb2xvcjMgPSBDb2xvcjMuZnJvbVJHQigyNTUsIDYwLCAxODApCnRpdGxlLkZvbnQgPSBFbnVtLkZvbnQuQ29kZQp0aXRsZS5UZXh0U2l6ZSA9IDE0CnRpdGxlLlBhcmVudCA9IGZyYW1lCgpsb2NhbCBidG4gPSBJbnN0YW5jZS5uZXcoIlRleHRCdXR0b24iKQpidG4uU2l6ZSA9IFVEaW0yLm5ldygwLCAxMDAsIDAsIDMwKQpidG4uUG9zaXRpb24gPSBVRGltMi5uZXcoMCwgMTAsIDAsIDUwKQpidG4uQmFja2dyb3VuZENvbG9yMyA9IENvbG9yMy5mcm9tUkdCKDQwLCAzNCwgNDgpCmJ0bi5UZXh0ID0gIlByb2JlIgpidG4uVGV4dENvbG9yMyA9IENvbG9yMy5mcm9tUkdCKDIzMCwgMjI1LCAyMzUpCmJ0bi5Gb250ID0gRW51bS5Gb250LkNvZGUKYnRuLlBhcmVudCA9IGZyYW1lCgpwcmludCgiW29kaWw5XSBmb3JjZSBsb2FkZXIgc3Vrc2VzISIpCmVuZAo="
    local decoded = game:GetService("HttpService"):Base64Decode(encoded) -- need base64 decode
    -- delta usually has base64 builtin or we use crypt
    if not decoded then
        if syn and syn.crypt and syn.crypt.base64 then
            decoded = syn.crypt.base64.decode(encoded)
        elseif crypt and crypt.base64 then
            decoded = crypt.base64.decode(encoded)
        end
    end
    
    if not decoded or decoded == "" then
        error("Gagal decode script. Delta gak support Base64 atau crypt.")
    end

    local func, load_err = loadstring(decoded)
    if not func then
        error("Loadstring error: " .. tostring(load_err))
    end
    func()
end)

if ok then
    print("[odil9] decode + loadstring sukses")
else
    warn("[odil9] force load GAGAL: ", err)
    -- FALLBACK: pakai loadstring langsung tanpa encode (kalau Delta support loadstring)
    print("[odil9] coba fallback loadstring minimal...")
    local fallback_code = [[
        print("[odil9] fallback sukses")
        local gui = Instance.new("ScreenGui")
        gui.Name = "odil9_fallback"
        gui.ResetOnSpawn = false
        gui.Parent = gethui() or game:GetService("CoreGui")
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0, 300, 0, 200)
        f.Position = UDim2.new(0, 20, 0, 20)
        f.BackgroundColor3 = Color3.fromRGB(18, 16, 22)
        f.BorderSizePixel = 2
        f.BorderColor3 = Color3.fromRGB(255, 60, 180)
        f.Parent = gui
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -20, 1, -20)
        t.Position = UDim2.new(0, 10, 0, 10)
        t.BackgroundTransparency = 1
        t.Text = "odil9 fallback — kalo ini muncul, loadstring jalan"
        t.TextColor3 = Color3.fromRGB(255, 60, 180)
        t.Font = Enum.Font.Code
        t.TextSize = 14
        t.TextWrapped = true
        t.Parent = f
    ]]
    local f, f_err = loadstring(fallback_code)
    if f then
        pcall(f)
        print("[odil9] fallback loadstring sukses")
    else
        warn("[odil9] fallback loadstring GAGAL: ", f_err)
        warn("[odil9] Delta lu kemungkinan nge-block loadstring total. Cek setting executor.")
    end
end
