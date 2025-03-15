#!/bin/bash

#
# Copyright (c) 2024. Devtron Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#!/bin/bash
rm -rf ./env-config.js
touch ./env-config.js

# Bắt đầu file với một IIFE (Immediately Invoked Function Expression) để chạy ngay khi load
echo "(function () {" >> ./env-config.js

# Khởi tạo window._env_
echo "  window._env_ = {" >> ./env-config.js

# Đọc và xử lý biến từ .env hoặc biến môi trường container
while read -r line || [[ -n "$line" ]]; do
  if printf '%s\n' "$line" | grep -q -e '='; then
    varname=$(printf '%s\n' "$line" | sed -e 's/=.*//')
    varvalue=$(printf '%s\n' "$line" | sed -e 's/^[^=]*=//')
    value="${!varname}"
    if [ -z "$value" ]; then
      value="$varvalue"
    fi
    if [[ "$value" == "true" ]] || [[ "$value" == "false" ]]; then
      echo "    $varname: $value," >> ./env-config.js
    else
      echo "    $varname: \"$value\"," >> ./env-config.js
    fi
  fi
done < .env

# Kết thúc object window._env_
echo "  };" >> ./env-config.js

# Thêm logic shim để ánh xạ window._env_ sang process.env
echo "  if (!window._env_) {" >> ./env-config.js
echo "    console.warn('window._env_ is not defined, falling back to defaults');" >> ./env-config.js
echo "    window._env_ = {};" >> ./env-config.js
echo "  }" >> ./env-config.js
echo "  window.process = window.process || {};" >> ./env-config.js
echo "  window.process.env = window.process.env || {};" >> ./env-config.js
echo "  Object.assign(window.process.env, window._env_);" >> ./env-config.js

# Kết thúc IIFE
echo "})();" >> ./env-config.js
