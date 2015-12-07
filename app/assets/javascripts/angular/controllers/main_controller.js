photoBoothApp.controller('MainCtrl', [
  '$scope',
  '$http',
  function ($scope, $http) {

    $scope.takePicture = function () {
      $http.post('/picture_sets.json').success(function (data) {
        $scope.picture_sets.unshift(data);
      }).error(function (data) {
        alert(data.error);
        $scope.addAlert();
        //$scope.alerts.push({msg: 'Another alert!'});
      })
    };

    $scope.update = function () {
      $http.get('/picture_sets/list.json').success(function (data) {
        $scope.picture_sets = data;
      }).error(function (data) {
        alert(data.error);
        $scope.addAlert(data.error);
      })
    };

    $scope.alerts = [];
    $scope.addAlert = function () {
      $scope.alerts.push({msg: 'Another alert!'});
    };

    $scope.update();

  }]);
