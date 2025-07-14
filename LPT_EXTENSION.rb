require 'sketchup.rb'
PLUGIN_DIR = File.dirname(__FILE__) # Đặt ở đầu file

module LPT_SOLUTION
  module LPT_EXTENSION

#CHECK VERSION#
            require 'open-uri'
            require 'json'

            VERSION = "1.2.4"
            VERSION_URL = "https://phuoctuan94.github.io/LPT_SOLUTION/version.json"
                def self.check_for_update_silent
          begin
            json = URI.open(VERSION_URL).read
            data = JSON.parse(json)
            latest = data["version"]

            if latest > VERSION
              temp_dir = File.join(PLUGIN_DIR, "temp")
              Dir.mkdir(temp_dir) unless Dir.exist?(temp_dir)

              new_file_url = data["main_rb_url"]
              temp_file_path = File.join(temp_dir, "LPT_EXTENSION_new.rb")
              URI.open(new_file_url) do |remote|
                File.open(temp_file_path, "wb") do |file|
                  file.write(remote.read)
                end
              end

              # Đánh dấu cần cập nhật ở lần khởi động tiếp theo
              flag_file = File.join(PLUGIN_DIR, "update.flag")
              File.write(flag_file, "update_pending")

            end
          rescue => e
            puts "[LPT_SOLUTION] Không kiểm tra được cập nhật: #{e.message}"
          end
        end
        
  UI.messagebox("Bản mới 1.2.4 đã cập nhật chức năng XYZ"<br>"Tắt mở lại")
        
        
                                  flag_file = File.join(PLUGIN_DIR, "update.flag")
                          temp_file = File.join(PLUGIN_DIR, "temp", "LPT_EXTENSION_new.rb")
                          main_file = File.join(PLUGIN_DIR, "LPT_EXTENSION.rb")

                          if File.exist?(flag_file) && File.exist?(temp_file)
                            begin
                              FileUtils.cp(temp_file, main_file)
                              File.delete(flag_file)
                              File.delete(temp_file)
                              puts "[LPT_SOLUTION] Đã cập nhật plugin thành công."
                            rescue => e
                              puts "[LPT_SOLUTION] Lỗi khi cập nhật: #{e.message}"
                            end
                          end

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



    # ✅ Tạo menu duy nhất 1 lần
    unless file_loaded?(__FILE__)
      self.create_template_file
      self.check_for_update_silent
                
                    # --- Menu ---
                    menu = UI.menu('Plugins').add_submenu('LPT_SOLUTION') 
                    menu.add_item('Xóa Layer Rác [Từ file Data]') { self.delete_layers_from_file } 
                    menu.add_item('Xóa Text và Dimension') { self.show_confirmation_dialog }
                    menu.add_item("Xóa nét (Egde) thừa") {self.show_edge_manager }
                    menu.add_item('📂 Mở thư mục Data') { self.open_note_folder }
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

                    toolbar.restore                    
      file_loaded(__FILE__)
    end





  end #LPT_EXTENSION
end #LPT_SOLUTIONS
