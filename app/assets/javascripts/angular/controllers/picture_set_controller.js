photoBoothApp.controller('PictureSetCtrl', [
  '$scope',
  '$http',
  '$uibModal',
  '$log',
  '$routeParams',
  function ($scope, $http, $uibModal, $log, $routeParams) {

    $log.log('$routeParams.pictureSetId: ' + $routeParams.pictureSetId)
    $scope.pictureSetId = $routeParams.pictureSetId;

    $scope.loadPictureSet = function () {
      $http({
        method: 'GET',
        url: '/picture_sets/' + $routeParams.pictureSetId
      }).then(function successCallback(response) {
        $scope.picture_set = response.data;
        $log.log('pictureSet data: ' + $scope.picture_set)
      }, function errorCallback(response) {
        //$scope.alerts.push({type: 'error', msg: response.data.error});
      });
    };

    $scope.loadPictureSet()

  }]);

