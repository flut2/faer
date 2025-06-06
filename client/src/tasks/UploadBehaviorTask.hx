package tasks;

import ui.dialogs.Dialog;
import openfl.events.Event;
import account.Account;
import appengine.RequestHandler;
import lib.tasks.Task;

class UploadBehaviorTask extends Task {
	public static var data: String;
	public static var name: String;

	override public function startTask() {
		RequestHandler.setParameter("email", Account.email);
		RequestHandler.setParameter("password", Account.password);
		RequestHandler.setParameter("data", data);
		RequestHandler.setParameter("name", name);
		RequestHandler.complete.once(this.onComplete);
		RequestHandler.sendRequest("/app/uploadBehavior");
	}

	private function onComplete(compData: CompletionData) {
		if (compData.result.indexOf("<Error>") == -1 && compData.success) {
			var dialog = new Dialog('Successfully uploaded $name to the server', 'Success', "Close", null);
			dialog.addEventListener(Dialog.BUTTON1_EVENT, (_: Event) -> {
				Global.layers.dialogs.closeDialogs();
			});
			Global.layers.dialogs.openDialog(dialog);
		} else {
			var dialog = new Dialog('Failed to upload $name to the server: ${compData.result}', 'Error', "Close", null);
			dialog.addEventListener(Dialog.BUTTON1_EVENT, (_: Event) -> {
				Global.layers.dialogs.closeDialogs();
			});
			Global.layers.dialogs.openDialog(dialog);
		}

		completeTask(compData.success, compData.result);
	}
}
