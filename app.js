
$("#createRoomBtn").onclick = () => {
    if (!currentUser) {
        openAuth();
        return;
    }

    openModal(`
        <h2>สร้างห้องเล่นเกม</h2>
        <p>สร้างห้องเพื่อให้สมาชิกคนอื่นเข้าร่วม</p>

        <form id="roomForm">
            <div class="form-group">
                <label>ชื่อห้อง</label>
                <input class="form-control" name="title" required maxlength="45">
            </div>

            <div class="form-group">
                <label>เลือกเกม</label>
                <select class="form-control" name="game">
                    ${games.map(g => `<option>${g.name}</option>`).join("")}
                </select>
            </div>

            <div class="form-group">
                <label>จำนวนผู้เล่นสูงสุด</label>
                <select class="form-control" name="max_players">
                    <option>4</option>
                    <option>5</option>
                    <option>6</option>
                    <option>8</option>
                </select>
            </div>

            <div class="form-group">
                <label>สไตล์การเล่น</label>
                <select class="form-control" name="style">
                    <option>เล่นชิล ๆ</option>
                    <option>สายวางแผน</option>
                    <option>สายปาร์ตี้</option>
                </select>
            </div>

            <button class="btn btn-primary form-submit">สร้างห้อง</button>
        </form>
    `);

    $("#roomForm").onsubmit = async e => {
        e.preventDefault();

        const submit = e.target.querySelector("button");
        submit.disabled = true;

        try {
            const { data: { user }, error: authError } =
                await db.auth.getUser();

            if (authError || !user) {
                throw new Error("กรุณาเข้าสู่ระบบใหม่");
            }

            const { data: profile, error: profileError } =
                await db.from("profiles")
                    .select("id")
                    .eq("id", user.id)
                    .maybeSingle();

            if (profileError) throw profileError;

            // สร้างโปรไฟล์หากยังไม่มี
            if (!profile) {
                const { error } = await db.from("profiles").insert({
                    id: user.id,
                    display_name:
                        user.user_metadata?.display_name || "สมาชิก"
                });

                if (error) throw error;
            }

            const d = Object.fromEntries(new FormData(e.target));

            const { data, error } = await db.from("rooms")
                .insert({
                    title: d.title,
                    game: d.game,
                    max_players: Number(d.max_players),
                    style: d.style,
                    host_id: user.id
                })
                .select()
                .single();

            if (error) throw error;

            const { error: joinError } = await db.from("room_members")
                .insert({
                    room_id: data.id,
                    user_id: user.id
                });

            if (joinError) {
                toast("สร้างห้องแล้ว แต่เข้าร่วมห้องไม่สำเร็จ: " + joinError.message);
            } else {
                toast("สร้างห้องเรียบร้อย!");
            }

            closeModal();
            await loadRooms();

        } catch (err) {
            toast(err.message || "เกิดข้อผิดพลาด");
        } finally {
            submit.disabled = false;
        }
    };
};
