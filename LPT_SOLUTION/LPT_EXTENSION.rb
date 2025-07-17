require 'sketchup.rb'
require 'fileutils'
PLUGIN_DIR = File.dirname(__FILE__)

module LPT_SOLUTION
  module LPT_EXTENSION

#CHECK VERSION#
# Thêm VERSION vào đây để dễ dàng quản lý
VERSION = "2.0.0" # Cập nhật phiên bản này mỗi khi bạn có bản cập nhật mới

# Hàm kiểm tra và cập nhật extension
def self.check_for_updates
  github_raw_url_base = "https://raw.githubusercontent.com/PhuocTuan94/LPT_SOLUTION/refs/heads/main" # Thay đổi bằng username và repo của bạn
  version_file_url = "#{github_raw_url_base}VERSION.txt" # Một file đơn giản chỉ chứa số phiên bản mới nhất

  # Tải phiên bản mới nhất từ GitHub
  current_version = VERSION
  latest_version = nil

  begin
    require 'open-uri'
    open(version_file_url) do |f|
      latest_version = f.read.strip
    end
  rescue => e
    UI.messagebox("Không thể kiểm tra cập nhật. Lỗi: #{e.message}")
    return
  end

  if latest_version.nil?
    UI.messagebox("Không thể lấy thông tin phiên bản mới nhất từ GitHub.")
    return
  end

  if Gem::Version.new(latest_version) > Gem::Version.new(current_version)
    result = UI.messagebox("Có phiên bản mới (#{latest_version})! Bạn có muốn cập nhật không?", MB_YESNO)
    if result == IDYES
      update_extension(github_raw_url_base)
    else
      UI.messagebox("Đã hủy cập nhật.")
    end
  else
    UI.messagebox("Bạn đang sử dụng phiên bản mới nhất (#{current_version}).")
  end
end

# Hàm thực hiện cập nhật
def self.update_extension(github_raw_url_base)
  extension_files = [
    "lpt_solution.rb", # Tên file chính của extension
    "icons/about_16.png",
    "icons/about_32.png",
    "icons/del_layer_16.png",
    "icons/del_layer_32.png",
    "icons/del_tedim_16.png",
    "icons/del_tedim_32.png",
    "icons/edge_delete_16.png",
    "icons/edge_delete_32.png",
    # Thêm tất cả các file khác của extension vào đây
    # Ví dụ: "subfolder/another_file.rb" nếu có
  ]

  model = Sketchup.active_model
  model.close_active
  sleep(0.5) # Chờ một chút để SketchUp đóng model hiện tại (giảm thiểu lỗi khi ghi đè file đang mở)

  begin
    extension_files.each do |file_name|
      source_url = "#{github_raw_url_base}#{file_name}"
      target_path = File.join(PLUGIN_DIR, file_name)

      # Đảm bảo thư mục đích tồn tại
      FileUtils.mkdir_p(File.dirname(target_path)) unless File.exist?(File.dirname(target_path))

      puts "Tải xuống: #{source_url} tới #{target_path}"
      URI.open(source_url) do |source_file|
        File.open(target_path, "wb") do |target_file|
          target_file.write(source_file.read)
        end
      end
    end
    UI.messagebox("Cập nhật thành công! SketchUp sẽ khởi động lại để áp dụng các thay đổi.")
    Sketchup.send_action("quit:") # Khởi động lại SketchUp để tải lại extension
  rescue => e
    UI.messagebox("Có lỗi xảy ra trong quá trình cập nhật: #{e.message}\nBạn vui lòng thử lại hoặc cập nhật thủ công.")
    puts e.backtrace.join("\n")
  end
end

# --- Thêm mục Cập nhật vào menu và toolbar ---
# Bạn cần thêm các dòng này vào phần tạo menu/toolbar của bạn

# Trong phần menu:
# menu.add_item("Kiểm tra cập nhật") { self.check_for_updates }

# Trong phần toolbar (ví dụ):
# cmd_update = UI::Command.new('Kiểm tra cập nhật') {
#   self.check_for_updates
# }
# cmd_update.tooltip = 'Kiểm tra và cập nhật Extension'
# cmd_update.status_bar_text = 'Kiểm tra và cập nhật Extension từ GitHub'
# # Bạn có thể tạo icon cho nút cập nhật nếu muốn
# # cmd_update.small_icon = File.join(PLUGIN_DIR, "icons", "update_16.png")
# # cmd_update.large_icon = File.join(PLUGIN_DIR, "icons", "update_32.png")
# toolbar.add_item(cmd_update)
            
#CHECK VERSION#



#ĐOẠN TẠO FILE NOTE LAYER#
def self.create_template_file
  documents_path = File.expand_path("~/Documents")
  folder_path = File.join(documents_path, "LPT_SOLUTION")
  file_path = File.join(folder_path, "LAYERS TO DELETE.txt")

  begin
    Dir.mkdir(folder_path) unless Dir.exist?(folder_path)

    unless File.exist?(file_path)
      content = <<~TEXT
  # Danh sách các Layer cần xóa (mỗi dòng 1 tên Layer)
  #---------------------------#
  #LPT SOLUTION #Facebook
  https://www.facebook.com/TuanHuyFurniture/
  #---------------------------#
  Layer/Tags cần xóa: [TH_DELETE]
TEXT

      File.write(file_path, content)
    end
  rescue
    # Không làm gì cả nếu có lỗi
  end
end
#KẾT THÚC ĐOẠN TẠO FILE NOTE LAYER#



#BẮT ĐẦU ĐOẠN XÓA LAYER KHÔNG SỬ DỤNG#
  def self.delete_layers_from_file
  model = Sketchup.active_model
  layers = model.layers

  # Đường dẫn tới file note mặc định
  documents_path = File.expand_path("~/Documents")
  file_path = File.join(documents_path, "LPT_SOLUTION", "LAYERS TO DELETE.txt")

  return unless File.exist?(file_path)

  # Đọc file và trích xuất tên các layer nằm trong dấu []
  layer_names_to_delete = []

  File.foreach(file_path) do |line|
    # Bỏ qua dòng comment hoặc trắng
    next if line.strip.empty? || line.strip.start_with?("#")

    # Nếu có dạng [TH_DELETE, LAYER2], thì tách ra từng tên
    if line =~ /\[(.*?)\]/
      layer_list = $1.split(',').map(&:strip)
      layer_names_to_delete.concat(layer_list)
    end
  end

  model.start_operation("Xóa các Layer theo file", true)
  deleted_count = 0

  layer_names_to_delete.uniq.each do |layer_name|
    layer = layers[layer_name]
    if layer && layer != model.layers[0] # Không xóa Layer0
      begin
        layers.remove(layer)
        deleted_count += 1
      rescue => e
        puts "Không thể xóa layer '#{layer_name}': #{e.message}"
      end
    end
  end
  model.commit_operation
  UI.messagebox("Đã xóa #{deleted_count} layer!")
end
#KẾT THÚC ĐOẠN XÓA LAYER KHÔNG SỬ DỤNG#



#BẮT ĐẦU ĐOẠN XÓA TEXT & DIMENSIONS#
    def self.recursive_delete(entities)
      entities.grep(Sketchup::Text).each(&:erase!)
      entities.grep(Sketchup::Dimension).each(&:erase!)
      entities.grep(Sketchup::Group).each { |group| recursive_delete(group.entities) }
      entities.grep(Sketchup::ComponentInstance).each { |inst| recursive_delete(inst.definition.entities) }
    end

    def self.perform_deletion
      model = Sketchup.active_model
      model.start_operation("Delete Text and Dimensions", true)
      recursive_delete(model.entities)
      model.commit_operation
      UI.messagebox("Đã xóa tất cả Text và Dimension trong model.")
    end

    def self.show_confirmation_dialog
      html = <<-HTML
          <html>
            <head>
              <style>
                body { font-family: 'Segoe UI', Tahoma, sans-serif; margin: 12px; }
                button {
                  padding: 7px 15px;
                  margin: 10px;
                  font-size: 12px;
                }
                p {
                  font-size: 14px;
                  line-height: 1.5;
                }
              </style>
            </head>
            <body>
              <p>
                Việc xóa Dimension và Text này sẽ xóa cả "Sheet _" trong phần Nesting!<br>
                Bạn vẫn muốn xóa chứ?
              </p>
              <button onclick="sketchup.ok()">Xóa</button>
              <button onclick="sketchup.cancel()">Bỏ Qua</button>
            </body>
          </html>
HTML

      dialog = UI::HtmlDialog.new({
        :dialog_title => "[LPT_SOLUTION] - Xác nhận xóa",
        :preferences_key => "tuanhuy.delete_text_dimension",
        :scrollable => true,
        :resizable => true,
        :width => 385,
        :height => 160,
        :style => UI::HtmlDialog::STYLE_DIALOG
      })

      dialog.set_html(html)

      dialog.add_action_callback("ok") {
        dialog.close
        self.perform_deletion
      }

      dialog.add_action_callback("cancel") {
        dialog.close
      }

      dialog.show
      dialog.center
    end
#KẾT THÚC ĐOẠN XÓA TEXT & DIMENSIONS#



#BẮT ĐẦU CODE MỞ FOLDER HỖ TRỢ#
        def self.open_note_folder
          documents_path = File.expand_path("~/Documents")
          folder_path = File.join(documents_path, "LPT_SOLUTION")
          UI.openURL("file:///#{folder_path.gsub('\\', '/')}")
        end
#KẾT THÚC CODE MỞ FOLDER HỖ TRỢ#



#BẮT ĐẦU CODE MỞ FACEBOOK#
        def self.fbook(url = "https://www.facebook.com/TuanHuyFurniture/")
        UI.openURL(url)            
        end
#KẾT THÚC CODE MỞ FACEBOOK#



#XÓA EGDE THỪA TRONG BẢN VẼ#
          def self.show_edge_manager
            html = <<-HTML
              <html>
                <head>
                  <style>
                    body { font-family: 'Segoe UI', Tahoma, sans-serif; margin: 16px; }
                    h2 { font-size: 16px; }
                    button {
                      padding: 7px 15px;
                      margin: 10px 8px 10px 0;
                      font-size: 12px;
                    }
                    #result {
                      margin-top: 10px;
                      font-family: 'Segoe UI', Tahoma, sans-serif;
                      font-weight: normal;
                      color: green;
                    }
                  </style>
                </head>
                <body>
                  <h2>Xóa nét thừa</h2>
                  <p><i>[Xóa tất cả nét thừa trong file (Không bao gồm nét thừa trong mặt khối chưa Make Group/Component)]<p>
                  <button onclick="sketchup.check_edges()">Kiểm Tra & Chọn</button>
                  <button onclick="sketchup.delete_edges()">Xóa Tất Cả</button>
                  <p id="result"></p>
                </body>
              </html>
HTML

            dialog = UI::HtmlDialog.new({
              dialog_title: "[LPT_SOLUTION] - Quản Lý Nét Thừa",
              width: 441,
              height: 277,
              style: UI::HtmlDialog::STYLE_DIALOG
            })

            dialog.set_html(html)

            # ===== KIỂM TRA EDGE =====
            dialog.add_action_callback("check_edges") {
              model = Sketchup.active_model
              edges = model.entities.grep(Sketchup::Edge)
              model.selection.clear
              model.selection.add(edges)

              count = edges.size
              js = <<-JAVASCRIPT
                document.getElementById('result').innerHTML = 
                "Số nét thừa: #{count} trong file (Đã chọn)<br>Bạn có thể dùng lệnh Move (M) để kiểm tra";
JAVASCRIPT
              dialog.execute_script(js)
            }

            # ===== XÓA EDGE =====
            dialog.add_action_callback("delete_edges") {
              model = Sketchup.active_model
              model.start_operation("Xóa Edge trong model", true)

              edges = model.entities.grep(Sketchup::Edge)
              count = edges.size
              edges.each(&:erase!)

              model.commit_operation

              js = "document.getElementById('result').innerText = 'Đã xóa #{count} nét thừa.';"
              dialog.execute_script(js)
            }

            dialog.show
            dialog.center
          end
#XÓA EGDE THỪA TRONG BẢN VẼ#


#GIA CÔNG 1 MẶT#
class GiaCong1MatTool
  DEBUG = true

  def initialize(group)
    @group = group
    @face_source = nil
    @face_target = nil
    @path_source = nil
    @path_target = nil
    @hovered_face = nil
    @hovered_path = nil
  end

  def activate
    Sketchup.set_status_text("Chọn mặt có layer cần di chuyển... [Viền Đỏ]", SB_PROMPT)
  end

  def onMouseMove(flags, x, y, view)
    ph = view.pick_helper
    ph.do_pick(x, y)
    path = ph.path_at(0)

    @hovered_face = nil
    @hovered_path = nil
    view.tooltip = ""

    if path && path[-1].is_a?(Sketchup::Face) && path.include?(@group)
      face = path[-1]
      if @face_source.nil?
        @hovered_face = face
        @hovered_path = path
        view.tooltip = "Mặt cần di chuyển đi"
      elsif face_symmetric_with?(@face_source, @path_source, face, path)
        @hovered_face = face
        @hovered_path = path
        view.tooltip = "Di chuyển vào mặt này!"
      end
    end

    view.invalidate
  end

  def draw(view)
    return unless @hovered_face && @hovered_path

    trans = cumulative_transformation(@hovered_path)
    pts = @hovered_face.outer_loop.vertices.map { |v| v.position.transform(trans) }

    view.line_width = 3
    view.drawing_color = @face_source.nil? ? 'red' : 'blue'
    view.draw(GL_LINE_LOOP, pts)
  end

  def onLButtonDown(flags, x, y, view)
    if @hovered_face.nil? || @hovered_path.nil?
      UI.messagebox("Chọn mặt không hợp lệ. Tắt hộp thoại và chọn mặt khác!")
      return
    end

    if @face_source.nil?
      @face_source = @hovered_face
      @path_source = @hovered_path
      puts "[LPT] ✅ Đã chọn mặt nguồn"
      Sketchup.set_status_text("Click vào mặt cần đến...[Viền Xanh]", SB_PROMPT)
    else
      @face_target = @hovered_face
      @path_target = @hovered_path
      puts "[LPT] ✅ Đã chọn mặt đích. Bắt đầu di chuyển..."
      begin
        move_children_between_faces
      rescue => e
        puts "[LPT] ❌ Lỗi khi di chuyển: #{e.message}"
        puts e.backtrace.join("\n")
        UI.messagebox("Lỗi khi di chuyển: #{e.message}")
      end
      Sketchup.set_status_text("✅ Đã di chuyển group con từ mặt nguồn sang mặt đích.", SB_PROMPT)
      Sketchup.active_model.select_tool(nil)
    end
  end

  private

  def cumulative_transformation(path)
    path.reduce(Geom::Transformation.new) do |t, e|
      t * (e.respond_to?(:transformation) ? e.transformation : Geom::Transformation.new)
    end
  end

  def face_symmetric_with?(face1, path1, face2, path2)
    trans1 = cumulative_transformation(path1)
    trans2 = cumulative_transformation(path2)

    normal1 = face1.normal.transform(trans1).normalize
    normal2 = face2.normal.transform(trans2).normalize

    center1 = face1.bounds.center.transform(trans1)
    center2 = face2.bounds.center.transform(trans2)

    dot = normal1.dot(normal2)
    dist = center1.distance(center2)
    symmetric = dot < -0.95 && dist > 1e-3

    puts "🔍 Đối xứng? dot: #{dot.round(3)}, dist: #{dist.round(3)} → #{symmetric}" if DEBUG
    symmetric
  end

  def move_children_between_faces
    model = Sketchup.active_model
    model.start_operation("Gia Công 1 Mặt", true)

    trans_source = cumulative_transformation(@path_source)
    trans_target = cumulative_transformation(@path_target)

    center_source = @face_source.bounds.center.transform(trans_source)
    center_target = @face_target.bounds.center.transform(trans_target)
    move_vector = center_target - center_source

    puts "📌 Source: #{center_source.to_a.map { |n| "#{n.round(2)} mm" }.join(', ')}, " \
         "Target: #{center_target.to_a.map { |n| "#{n.round(2)} mm" }.join(', ')}"

    count = 0

    @group.entities.grep(Sketchup::Group).each do |child|
      next if child.deleted?

      child_path = [@group, child]
      child_trans = cumulative_transformation(child_path)
      child_center = child.bounds.center.transform(child_trans)

      d_source = child_center.distance(center_source)
      d_target = child_center.distance(center_target)

      if d_source < d_target - 1e-3
        puts "[LPT] 🔁 Di chuyển group con #{child.name}"
        child.transform!(Geom::Transformation.translation(move_vector))
        count += 1
      else
        puts "[LPT] ⏭ Bỏ qua #{child.name} (đã ở vị trí đích)"
      end
    end

    puts "➡ Tổng group con đã di chuyển: #{count}"
    model.commit_operation
  end
end

# Hàm gọi từ menu hoặc toolbar
def self.giacong_1mat
  model = Sketchup.active_model
  sel = model.selection
  group = sel.first
  unless group.is_a?(Sketchup::Group)
    UI.messagebox("Vui lòng chọn Tấm trước!")
    return
  end
  model.select_tool(GiaCong1MatTool.new(group))
end

#GIA CÔNG 1 MẶT#


    # ✅ Tạo menu duy nhất 1 lần
    unless file_loaded?(__FILE__)
      self.create_template_file
                
                    # --- Menu ---
                    menu = UI.menu('Plugins').add_submenu('LPT_SOLUTION') 
                    menu.add_item('Xóa Layer Rác [Từ file Data]') { self.delete_layers_from_file } 
                    menu.add_item('Xóa Text và Dimension') { self.show_confirmation_dialog }
                    menu.add_item("Xóa Nét (Egde) Thừa") {self.show_edge_manager }
                    menu.add_separator    
                    menu.add_item("🛠 Gia Công 1 Mặt") {self.giacong_1mat }
                    menu.add_separator                    
                    menu.add_item('📂 Mở Thư Mục Data') { self.open_note_folder }
                    menu.add_item('About') { self.fbook }
                    # --- Toolbar ---
                    toolbar = UI::Toolbar.new('LPT_SOLUTION')
                    
                    cmd_fbook = UI::Command.new('About') {
                      self.fbook
                    }
                    cmd_fbook.tooltip = 'About'
                    cmd_fbook.status_bar_text = 'About'
                    cmd_fbook.small_icon = File.join(PLUGIN_DIR, "icons", "about_16.png")
                    cmd_fbook.large_icon = File.join(PLUGIN_DIR, "icons", "about_32.png")
                    toolbar.add_item(cmd_fbook)

                toolbar.add_separator

                    cmd_delete_layers = UI::Command.new('Xóa Layer từ Note') {
                      self.delete_layers_from_file
                    }
                    cmd_delete_layers.tooltip = 'Xóa Layer Rác'
                    cmd_delete_layers.status_bar_text = '[Layer được người dùng khai báo]'
                    cmd_delete_layers.small_icon = File.join(PLUGIN_DIR, "icons", "del_layer_16.png")
                    cmd_delete_layers.large_icon = File.join(PLUGIN_DIR, "icons", "del_layer_32.png")
                    toolbar.add_item(cmd_delete_layers)

                    cmd_delete_text_dim = UI::Command.new('Xóa Text và Dimension') {
                      self.show_confirmation_dialog }
                    cmd_delete_text_dim.tooltip = 'Xóa toàn bộ Text & Dimension'
                    cmd_delete_text_dim.status_bar_text = 'Xóa toàn bộ Text & Dimension'
                    cmd_delete_text_dim.small_icon = File.join(PLUGIN_DIR, "icons", "del_tedim_16.png")
                    cmd_delete_text_dim.large_icon = File.join(PLUGIN_DIR, "icons", "del_tedim_32.png")
                    toolbar.add_item(cmd_delete_text_dim)

                    cmd_delete_edge = UI::Command.new('Xóa Nét Thừa') {
                      self.show_edge_manager}
                    cmd_delete_edge.tooltip = 'Xóa Nét Thừa'
                    cmd_delete_edge.status_bar_text = 'Xóa Nét Thừa'
                    cmd_delete_edge.small_icon = File.join(PLUGIN_DIR, "icons", "edge_delete_16.png")
                    cmd_delete_edge.large_icon = File.join(PLUGIN_DIR, "icons", "edge_delete_32.png")
                    toolbar.add_item(cmd_delete_edge)
                    toolbar.add_separator
                    
                    cmd_giacong_1mat = UI::Command.new('GIA CÔNG 1 MẶT') {
                      self.giacong_1mat}
                    cmd_giacong_1mat.tooltip = 'Gia Công 1 Mặt'
                    cmd_giacong_1mat.status_bar_text = 'Xử lý tấm gia công 2 mặt!'
                    cmd_giacong_1mat.small_icon = File.join(PLUGIN_DIR, "icons", "gc1m_16.png")
                    cmd_giacong_1mat.large_icon = File.join(PLUGIN_DIR, "icons", "gc1m_32.png")
                    toolbar.add_item(cmd_giacong_1mat)

                    toolbar.restore                    
      file_loaded(__FILE__)
    end

  end #LPT_EXTENSION
end #LPT_SOLUTIONS
