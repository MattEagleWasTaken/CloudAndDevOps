from azure.core.exceptions import ResourceExistsError
from azure.storage.blob import BlobSasPermissions, BlobServiceClient, generate_blob_sas
from datetime import datetime, timedelta
from flask import Flask, render_template, request
import os
from PIL import Image, UnidentifiedImageError 

# –––––––––– Environment Variables passed down from the Web App ––––––––––––––––––––––
connection_string = os.environ["STORAGE_CONNECTION_STRING"]
storage_account = os.environ["STORAGE_ACCOUNT_NAME"]
storage_container = os.environ["STORAGE_CONTAINER_NAME"]


# –––––––––– Connect to the Storage Account / Container –––––––––––––––––
blob_service_client = BlobServiceClient.from_connection_string(connection_string)

container_client = blob_service_client.get_container_client(storage_container)
account_key = blob_service_client.credential.account_key


# –––––––– Helper Function for Image Validation ––––––––––––––––––––––

def is_valid_image(file):
    try:
        # 1. Verify
        img = Image.open(file)
        img.verify()

        # 2. Reset stream and reopen for load()
        file.seek(0)
        img = Image.open(file)
        img.load()

        file.seek(0)  # Stream zurück an den Anfang für den späteren Azure Upload
        return True
    except (UnidentifiedImageError, IOError, SyntaxError):
        return False





app = Flask(__name__)

@app.route("/")
def page_1():
    blob_list = container_client.list_blobs()
    blob_data = []
    for blob in blob_list:
        expiry = datetime.now() + timedelta(hours=2)
        blob_client = container_client.get_blob_client(blob.name)
        sas_token = generate_blob_sas(
        account_name=storage_account,
        container_name=storage_container,
        blob_name= blob.name,
        account_key=account_key,
        permission=BlobSasPermissions(read=True),
        expiry=expiry
        )
        blob_url = blob_client.url
        blob_dl = blob_url + "?" + sas_token
        blob_data.append({"name": blob.name, "url": blob_dl})
    return render_template("page_1.html", blobs=blob_data)


@app.route("/upload", methods=["GET", "POST"])
def page_2():
    if request.method == "POST":
        file = request.files["file"] 
        if is_valid_image(file):
            filename = file.filename
            file_data = file.read()
            try:
                container_client.upload_blob(name=filename, data=file_data)
                success = "File-Upload successfull!"
                return render_template("page_2.html", success=success)
            except ResourceExistsError:
                error = "A file with this name already exists. Please rename it or choose a different file."
                return render_template("page_2.html", error=error)
        else: 
            error = "This File-format is not supported!"
            return render_template("page_2.html", error=error)
    return render_template("page_2.html")

if __name__ == "__main__":
    app.run(debug=True)


#app.run()

