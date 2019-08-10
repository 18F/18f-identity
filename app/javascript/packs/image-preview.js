import $ from 'jquery';

function imagePreview() {
  $('#doc_auth_image').on('change', function(event) {
    const files = event.target.files;
    const image = files[0];
    const reader = new FileReader();
    reader.onload = function(file) {
      const img = new Image();
      img.onload = function () {
        img.width = this.width;
        img.height = this.height;
        $('#target').html(img);
      };
      img.src = file.target.result;
      $('#target').html(img);
    };
    reader.readAsDataURL(image);
  });
}

document.addEventListener('DOMContentLoaded', imagePreview);
